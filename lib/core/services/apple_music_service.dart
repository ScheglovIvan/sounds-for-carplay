import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show ImageProvider, MemoryImage;
import 'package:permission_handler/permission_handler.dart';
import 'package:system_music/system_music.dart';

import '../models/now_playing.dart';
import 'app_launcher.dart';
import 'now_playing_source.dart';

/// Focus Drive's music surface — a mirror of the SYSTEM player, exactly like
/// the source app.
///
/// The app never streams or manages Apple Music content itself. The flow is:
///
/// 1. [openAppleMusic] opens the real Apple Music app (`music://` deep link via
///    `url_launcher`, with an `https://music.apple.com/` fallback).
/// 2. The user starts playback there.
/// 3. [nowPlaying] reflects the REAL system now-playing item (title, artist,
///    artwork, position) read through the local `system_music` plugin — no
///    bundled sounds, no mock playlist.
/// 4. [togglePlay] / [next] / [previous] drive
///    `MPMusicPlayerController.systemMusicPlayer` through that same plugin.
///    When the native side is unreachable ([canControl] is false) the UI hides
///    its transport buttons rather than showing controls that do nothing.
///
/// The position is OPTIONAL throughout: `currentPlaybackTime` is NaN until the
/// system player has been prepared, so the plugin reports "unknown" instead of
/// converting it. A track with no elapsed time still renders in full.
///
/// Reading the system item needs the real Apple Music / Media Library
/// authorization (`NSAppleMusicUsageDescription`), which [start] requests
/// through `permission_handler` at the natural moment — when Focus Drive's
/// music surface opens.
class AppleMusicService {
  AppleMusicService._();
  static final AppleMusicService instance = AppleMusicService._();

  /// Whether the user granted the real media-library authorization.
  final ValueNotifier<bool> authorized = ValueNotifier<bool>(false);

  /// What the SYSTEM is playing right now.
  final ValueNotifier<NowPlayingInfo> nowPlaying =
      ValueNotifier<NowPlayingInfo>(NowPlayingInfo.none);

  /// Whether transport control of the system player is actually available.
  /// False hides the transport buttons entirely.
  final ValueNotifier<bool> canControl = ValueNotifier<bool>(false);

  bool _started = false;
  StreamSubscription<SystemMusicTrack?>? _sub;

  /// Cached artwork, kept across polls so the bytes only cross the channel when
  /// the item actually changes.
  ImageProvider? _artwork;
  String? _artworkItemId;

  /// Open the Apple Music app so the user can start playback there.
  ///
  /// Falls back to the Apple Music web entry point when the app is not
  /// installed / the scheme cannot be opened. Returns false when neither
  /// worked, so the caller can say so instead of failing silently.
  Future<bool> openAppleMusic() async {
    if (kIsWeb) return false;
    if (await AppLauncher.music()) return true;
    return AppLauncher.openRaw('https://music.apple.com/');
  }

  /// Begin mirroring the system now-playing item.
  ///
  /// Safe to call repeatedly (subsequent calls only refresh availability).
  Future<void> start() async {
    if (kIsWeb) return;
    canControl.value = await SystemMusic.isAvailable();
    if (_started) return;
    _started = true;

    await ensureAuthorization();
    try {
      // Real system now-playing stream on device; null on the web preview.
      final Stream<SystemMusicTrack?>? tracks = await NowPlayingSource.start();
      _sub = tracks?.listen(
        _apply,
        onError: (Object e) => debugPrint('[music] now-playing stream: $e'),
      );
    } catch (e) {
      debugPrint('[music] now-playing unavailable: $e');
    }
  }

  /// Trigger the real iOS Apple Music / Media Library dialog. Reading the
  /// system now-playing item is gated on it.
  Future<bool> ensureAuthorization() async {
    if (kIsWeb) return false;
    try {
      PermissionStatus status = await Permission.mediaLibrary.status;
      if (!status.isGranted) {
        status = await Permission.mediaLibrary.request();
      }
      final bool ok = status.isGranted;
      authorized.value = ok;
      return ok;
    } catch (_) {
      return false;
    }
  }

  /// Play/pause the SYSTEM player (not the app's own audio).
  Future<void> togglePlay() async {
    final NowPlayingInfo info = nowPlaying.value;
    final bool ok =
        info.isPlaying ? await SystemMusic.pause() : await SystemMusic.play();
    if (ok) {
      // Optimistic flip; the now-playing stream corrects it if the system
      // disagrees.
      nowPlaying.value = info.copyWith(isPlaying: !info.isPlaying);
    }
  }

  Future<void> next() => SystemMusic.next();
  Future<void> previous() => SystemMusic.previous();

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }

  /// Map a plugin snapshot onto [NowPlayingInfo].
  ///
  /// A null duration/elapsed is carried through as "unknown" — it never
  /// downgrades the snapshot to "nothing playing", so the tile keeps rendering
  /// the track and its controls.
  void _apply(SystemMusicTrack? track) {
    if (track == null || !track.hasItem) {
      _artwork = null;
      _artworkItemId = null;
      nowPlaying.value = NowPlayingInfo.none;
      return;
    }

    final bytes = track.artwork;
    if (bytes != null) {
      _artwork = MemoryImage(bytes);
      _artworkItemId = track.itemId;
    } else if (!track.artworkUnchanged || track.itemId != _artworkItemId) {
      // Either a different item, or one that carries no artwork at all.
      _artwork = null;
      _artworkItemId = null;
    }

    nowPlaying.value = NowPlayingInfo(
      title: track.title,
      artist: track.artist,
      album: track.album,
      artwork: _artwork,
      duration: track.duration,
      elapsed: track.elapsed,
      isPlaying: track.isPlaying,
    );
  }
}
