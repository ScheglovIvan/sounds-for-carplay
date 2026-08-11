import 'package:system_music/system_music.dart';

/// Web/unsupported build: there is no system player to mirror, so the source
/// simply never emits. Callers then show "nothing playing" rather than anything
/// invented.
class NowPlayingSource {
  NowPlayingSource._();

  static Future<Stream<SystemMusicTrack?>?> start() async => null;
}
