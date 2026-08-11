import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// One snapshot of the iOS **system** now-playing item.
///
/// [duration] and [elapsed] are `null` when the position is UNKNOWN — which is a
/// normal state, not an error: `MPMusicPlayerController.currentPlaybackTime` is
/// NaN until the player has been prepared, and the native side drops any
/// non-finite value rather than converting it. Callers must render the track and
/// its transport controls anyway, just without a progress figure.
@immutable
class SystemMusicTrack {
  const SystemMusicTrack({
    this.itemId,
    this.title,
    this.artist,
    this.album,
    this.artwork,
    this.artworkUnchanged = false,
    this.duration,
    this.elapsed,
    this.isPlaying = false,
  });

  /// Stable id of the system's current item; null when nothing is loaded.
  final String? itemId;
  final String? title;
  final String? artist;
  final String? album;

  /// Encoded artwork bytes, when the item carries any AND they were re-sent.
  final Uint8List? artwork;

  /// True when the native side skipped the artwork because the caller already
  /// has the bytes for this [itemId] (see [nowPlaying]'s `knownArtworkItemId`).
  final bool artworkUnchanged;

  final Duration? duration;
  final Duration? elapsed;
  final bool isPlaying;

  /// Whether the system player actually holds an item right now.
  bool get hasItem => itemId != null;

  factory SystemMusicTrack.fromMap(Map<dynamic, dynamic> map) {
    final Object? bytes = map['artwork'];
    return SystemMusicTrack(
      itemId: _string(map['itemId']),
      title: _string(map['title']),
      artist: _string(map['artist']),
      album: _string(map['album']),
      artwork: bytes is Uint8List ? bytes : null,
      artworkUnchanged: map['artworkUnchanged'] == true,
      duration: _duration(map['durationMs']),
      elapsed: _duration(map['elapsedMs']),
      isPlaying: map['isPlaying'] == true,
    );
  }

  static String? _string(Object? value) {
    if (value is! String) return null;
    final String s = value.trim();
    return s.isEmpty ? null : s;
  }

  /// An absent or nonsensical key means "unknown", never zero.
  static Duration? _duration(Object? value) {
    if (value is! int || value < 0) return null;
    return Duration(milliseconds: value);
  }
}

/// Access to the iOS **system** music player.
///
/// Backed by `MPMusicPlayerController.systemMusicPlayer` on the native side, so
/// these calls read and drive whatever the Apple Music / Music app is playing —
/// the app never plays audio of its own here. Everything is a safe no-op off
/// iOS.
class SystemMusic {
  SystemMusic._();

  static const MethodChannel _channel = MethodChannel('system_music');

  /// Cached result of the availability probe (null until first checked).
  static bool? _available;

  static bool get _isIos =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Whether the native player is actually reachable from Dart.
  ///
  /// False on web/Android and false if the plugin did not register (in which
  /// case callers must HIDE their transport buttons rather than show controls
  /// that do nothing). The probe is a real channel call, so a missing native
  /// side is detected instead of assumed.
  static Future<bool> isAvailable() async {
    final bool? known = _available;
    if (known != null) return known;
    if (!_isIos) {
      _available = false;
      return false;
    }
    try {
      await _channel.invokeMethod<bool>('isPlaying');
      _available = true;
    } on MissingPluginException {
      _available = false;
    } catch (_) {
      // The plugin answered (e.g. a PlatformException) — it is registered.
      _available = true;
    }
    return _available!;
  }

  /// Resume the system player.
  static Future<bool> play() => _invoke('play');

  /// Pause the system player.
  static Future<bool> pause() => _invoke('pause');

  /// Skip to the next item in the system player's queue.
  static Future<bool> next() => _invoke('next');

  /// Skip to the previous item in the system player's queue.
  static Future<bool> previous() => _invoke('previous');

  /// Whether the system player is currently playing.
  static Future<bool> isPlaying() => _invoke('isPlaying');

  /// Read the SYSTEM now-playing item once.
  ///
  /// Pass [knownArtworkItemId] with the id whose artwork bytes the caller
  /// already holds; the native side then reports [SystemMusicTrack.artworkUnchanged]
  /// instead of re-sending them. Returns null when the native side is
  /// unreachable — never a made-up track.
  static Future<SystemMusicTrack?> nowPlaying({String? knownArtworkItemId}) async {
    if (!_isIos) return null;
    try {
      final Map<dynamic, dynamic>? map =
          await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'nowPlaying',
        <String, dynamic>{'artworkItemId': knownArtworkItemId},
      );
      _available = true;
      if (map == null) return null;
      return SystemMusicTrack.fromMap(map);
    } on MissingPluginException {
      _available = false;
      return null;
    } catch (e) {
      debugPrint('[system_music] nowPlaying failed: $e');
      return null;
    }
  }

  /// Poll the system now-playing item, so the UI tracks what the Music app is
  /// doing while it is on screen.
  ///
  /// The generator stops as soon as the subscription is cancelled. Artwork
  /// bytes are only carried across the channel when the item changes.
  static Stream<SystemMusicTrack?> watch({
    Duration interval = const Duration(seconds: 1),
  }) async* {
    if (!_isIos) return;
    String? artworkItemId;
    while (true) {
      final SystemMusicTrack? track =
          await nowPlaying(knownArtworkItemId: artworkItemId);
      if (track != null && track.artwork != null) {
        artworkItemId = track.itemId;
      } else if (track == null || !track.artworkUnchanged) {
        artworkItemId = null;
      }
      yield track;
      await Future<void>.delayed(interval);
    }
  }

  static Future<bool> _invoke(String method) async {
    if (!_isIos) return false;
    try {
      final bool? ok = await _channel.invokeMethod<bool>(method);
      _available = true;
      return ok ?? false;
    } on MissingPluginException {
      _available = false;
      return false;
    } catch (e) {
      debugPrint('[system_music] $method failed: $e');
      return false;
    }
  }
}
