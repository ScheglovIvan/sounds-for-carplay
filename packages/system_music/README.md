# system_music

A tiny **local** Flutter plugin that reads and drives iOS's system music player —
`MPMusicPlayerController.systemMusicPlayer` — the controller that owns whatever
the Apple Music / Music app is playing.

There is no pub package for this, and it deliberately lives here (a path
dependency in the app's `pubspec.yaml`) rather than in `ios/Runner/`: the build
pipeline re-runs `flutter create --platforms=ios,android .` on every build, so
anything hand-registered in `AppDelegate` or `project.pbxproj` would be wiped.
A plugin package is re-registered automatically by the Flutter tool.

```dart
await SystemMusic.play();
await SystemMusic.pause();
await SystemMusic.next();
await SystemMusic.previous();

// Whether the native side is actually reachable (false on Android/web, or if
// the plugin failed to register) — callers hide transport UI when false.
final bool ok = await SystemMusic.isAvailable();

// What the system is playing right now: title / artist / album / artwork /
// duration / elapsed. `watch()` polls it as a stream.
final SystemMusicTrack? track = await SystemMusic.nowPlaying();
```

## NaN positions are normal — never convert unguarded

`currentPlaybackTime` returns **NaN** until the system player has been prepared
to play in this process, including while `nowPlayingItem` is non-nil and
`playbackState` is playing; `playbackDuration` can be NaN too. Swift **traps**
(`EXC_BREAKPOINT`) on `Int(NaN)`, which is exactly how the third-party
`nowplaying` package used to crash this app on entering Focus Drive.

So: every MediaPlayer `Double` goes through `milliseconds(_:)`, which checks
`isFinite` before **and** after the `* 1000`, and returns `nil` instead of
converting. `durationMs` / `elapsedMs` are therefore **optional keys** on the
channel — absent means *unknown*, never `0`, and Dart surfaces them as
`SystemMusicTrack.duration` / `.elapsed` being `null`. A track with no elapsed
time still renders in full; only the progress figure is omitted.

Requires `NSAppleMusicUsageDescription` in `Info.plist` (injected by the build
pipeline from the app's `ios_permissions.json`). iOS only; every call is a safe
no-op elsewhere.
