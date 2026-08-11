import 'package:system_music/system_music.dart';

/// Device build: the REAL system now-playing item, read through our own local
/// `system_music` plugin (`MPMusicPlayerController.systemMusicPlayer`).
///
/// We own the Swift here, which is the point: every `Double` coming out of
/// MediaPlayer (`currentPlaybackTime`, `playbackDuration`) is checked for
/// finiteness before it is converted, so a NaN position can never trap.
class NowPlayingSource {
  NowPlayingSource._();

  static Future<Stream<SystemMusicTrack?>?> start() async {
    if (!await SystemMusic.isAvailable()) return null;
    return SystemMusic.watch();
  }
}
