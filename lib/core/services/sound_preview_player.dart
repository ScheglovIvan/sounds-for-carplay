import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../models/sound.dart';

/// Central playback service for the bundled sound library.
///
/// A single [AudioPlayer] is shared app-wide so that only ONE clip is ever
/// audible at a time — starting a new preview (or firing a slot's assigned
/// departure/arrival cue) automatically stops whatever was playing. Every
/// bundled clip lives under `assets/audio/<sha>.mp3` and is addressed through
/// [Sound.audioPlayerPath].
///
/// This is the one place that wires the app spec's `content.audio` triggers to
/// real audio: the sound-picker preview button calls [toggle]; the assign flow
/// and the drive-cue simulator call [playSound]. [nowPlayingId] lets any
/// widget reflect the active clip (e.g. the row's play/pause glyph).
class SoundPreviewPlayer {
  SoundPreviewPlayer._() {
    // When a clip finishes on its own, clear the active-id indicator so the row
    // returns to its "paused" look. Manual stops/restarts update [nowPlayingId]
    // directly, so we intentionally do NOT also react to raw state changes here
    // (a `stopped` event fired mid-restart would otherwise clear the new clip's
    // indicator via a late microtask).
    _player.onPlayerComplete.listen((_) => nowPlayingId.value = null);
  }

  /// App-wide singleton.
  static final SoundPreviewPlayer instance = SoundPreviewPlayer._();

  final AudioPlayer _player = AudioPlayer(playerId: 'sound_preview');

  /// Id of the clip currently playing, or null when nothing is audible.
  final ValueNotifier<String?> nowPlayingId = ValueNotifier<String?>(null);

  /// Whether [sound] is the clip currently playing.
  bool isPlaying(Sound sound) => nowPlayingId.value == sound.id;

  /// Preview toggle used by the picker's play/pause button: tapping the active
  /// clip stops it, tapping any other clip switches playback to it.
  Future<void> toggle(Sound sound) async {
    if (nowPlayingId.value == sound.id) {
      await stop();
    } else {
      await playSound(sound);
    }
  }

  /// Play [sound] from the start, replacing any clip already playing. This is
  /// the primitive every trigger maps onto — a picker preview, assigning a
  /// sound, or a simulated departure/arrival/home cue event.
  Future<void> playSound(Sound sound) async {
    try {
      await _player.stop();
      nowPlayingId.value = sound.id;
      await _player.play(AssetSource(sound.audioPlayerPath));
    } catch (_) {
      // Never let a missing/undecodable asset crash the UI.
      nowPlayingId.value = null;
    }
  }

  /// Stop playback and clear the active-clip indicator.
  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {
      // ignore
    }
    nowPlayingId.value = null;
  }

  /// Release the underlying player (call from the app's dispose path).
  Future<void> dispose() async {
    await _player.dispose();
    nowPlayingId.dispose();
  }
}
