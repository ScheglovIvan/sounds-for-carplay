import 'package:flutter/widgets.dart';

/// A snapshot of the SYSTEM now-playing item (what the Music / Apple Music app
/// is playing right now), as read through the local `system_music` plugin.
///
/// Nothing here is ever invented by the app: an empty [NowPlayingInfo.none]
/// simply means the system is not playing anything we can read.
@immutable
class NowPlayingInfo {
  const NowPlayingInfo({
    this.title,
    this.artist,
    this.album,
    this.artwork,
    this.duration,
    this.elapsed,
    this.isPlaying = false,
  });

  /// Nothing is playing (or we have no authorization to read it).
  static const NowPlayingInfo none = NowPlayingInfo();

  final String? title;
  final String? artist;
  final String? album;

  /// Real artwork from the system now-playing item, when it carries any.
  final ImageProvider? artwork;

  /// Track length, or null when the system does not report a usable one.
  final Duration? duration;

  /// Position within the track, or null when it is UNKNOWN — the normal state
  /// until the system player has been prepared to play. A null position never
  /// hides the track or its transport controls; it only hides the progress
  /// figure.
  final Duration? elapsed;

  /// Whether the system player is currently playing (vs. paused).
  final bool isPlaying;

  /// True when the system reported an actual track we can display.
  bool get hasTrack =>
      (title != null && title!.isNotEmpty) ||
      (artist != null && artist!.isNotEmpty);

  /// True only when there is a real position to draw a progress figure from.
  bool get hasPosition => elapsed != null;

  NowPlayingInfo copyWith({bool? isPlaying}) => NowPlayingInfo(
        title: title,
        artist: artist,
        album: album,
        artwork: artwork,
        duration: duration,
        elapsed: elapsed,
        isPlaying: isPlaying ?? this.isPlaying,
      );
}
