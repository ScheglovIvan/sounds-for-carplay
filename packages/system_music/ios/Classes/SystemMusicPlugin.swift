import Flutter
import MediaPlayer
import UIKit

/// Bridges Dart to `MPMusicPlayerController.systemMusicPlayer`, the controller
/// that owns playback in the Music / Apple Music app.
///
/// Registered automatically by the Flutter tool because this ships as a plugin
/// package (nothing is hand-wired into AppDelegate, which the build pipeline
/// regenerates). Requires `NSAppleMusicUsageDescription` in Info.plist.
///
/// This plugin is also the app's source of now-playing METADATA (title, artist,
/// album, artwork, duration, elapsed time). See `milliseconds(_:)` for why every
/// floating-point value from MediaPlayer is funnelled through a finiteness
/// guard before it crosses the channel.
public class SystemMusicPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "system_music",
      binaryMessenger: registrar.messenger()
    )
    let instance = SystemMusicPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  private let player = MPMusicPlayerController.systemMusicPlayer

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "play":
      player.play()
      result(true)
    case "pause":
      player.pause()
      result(true)
    case "next":
      player.skipToNextItem()
      result(true)
    case "previous":
      // Matches the Music app: restart the track, or step back when it just
      // started. The elapsed time goes through the finiteness guard — it is NaN
      // until the player has been prepared, and NaN must never reach a
      // comparison we depend on.
      if let elapsed = SystemMusicPlugin.finiteSeconds(player.currentPlaybackTime), elapsed > 3 {
        player.skipToBeginning()
      } else {
        player.skipToPreviousItem()
      }
      result(true)
    case "isPlaying":
      result(player.playbackState == .playing)
    case "nowPlaying":
      let args = call.arguments as? [String: Any]
      result(nowPlayingPayload(knownArtworkItemId: args?["artworkItemId"] as? String))
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Now playing

  /// A snapshot of what the SYSTEM player holds right now.
  ///
  /// `durationMs` and `elapsedMs` are OPTIONAL keys: a missing key means the
  /// position is genuinely UNKNOWN (see `milliseconds(_:)`), never zero. Dart
  /// renders the track and its transport controls regardless.
  private func nowPlayingPayload(knownArtworkItemId: String?) -> [String: Any] {
    var payload: [String: Any] = [
      "isPlaying": player.playbackState == .playing,
    ]
    guard let item = player.nowPlayingItem else {
      // Nothing loaded (e.g. nothing has been played since boot), or the media
      // library authorization is not granted.
      return payload
    }

    let itemId = String(item.persistentID)
    payload["itemId"] = itemId
    if let title = item.title, !title.isEmpty { payload["title"] = title }
    if let artist = item.artist, !artist.isEmpty { payload["artist"] = artist }
    if let album = item.albumTitle, !album.isEmpty { payload["album"] = album }

    if let ms = SystemMusicPlugin.milliseconds(item.playbackDuration) {
      payload["durationMs"] = ms
    }
    if let ms = SystemMusicPlugin.milliseconds(player.currentPlaybackTime) {
      payload["elapsedMs"] = ms
    }

    // Artwork is large, and Dart polls this often — re-send it only when the
    // item actually changed.
    if let known = knownArtworkItemId, known == itemId {
      payload["artworkUnchanged"] = true
    } else if let data = SystemMusicPlugin.artworkData(item.artwork) {
      payload["artwork"] = FlutterStandardTypedData(bytes: data)
    }
    return payload
  }

  private static func artworkData(_ artwork: MPMediaItemArtwork?) -> Data? {
    guard let artwork = artwork else { return nil }
    let bounds = artwork.bounds.size
    // Items with no usable artwork report a zero (or non-finite) bounds; asking
    // for an image at that size is pointless and `min`/`max` on NaN is junk.
    guard bounds.width.isFinite, bounds.height.isFinite,
          bounds.width >= 1, bounds.height >= 1 else { return nil }
    let side = min(max(bounds.width, bounds.height), 512)
    guard let image = artwork.image(at: CGSize(width: side, height: side)) else { return nil }
    return image.jpegData(compressionQuality: 0.85)
  }

  // MARK: - Floating-point guards

  /// A usable, finite number of seconds from MediaPlayer, or nil.
  ///
  /// `MPMusicPlayerController.currentPlaybackTime` returns **NaN** until the
  /// system player has been prepared to play in this process — including while
  /// `nowPlayingItem` is non-nil and `playbackState` is `.playing`. So does
  /// `MPMediaItem.playbackDuration` for some items. These are NORMAL states,
  /// not error states.
  private static func finiteSeconds(_ value: Double) -> Double? {
    guard value.isFinite, value >= 0 else { return nil }
    return value
  }

  /// Whole milliseconds for the platform channel, or nil when the source value
  /// is not a finite, representable number.
  ///
  /// Swift traps (`EXC_BREAKPOINT`) on `Int(NaN)` and on `Int(x)` outside `Int`'s
  /// range, which is exactly how a NaN `currentPlaybackTime` used to kill the
  /// app. Nothing in this plugin converts a MediaPlayer `Double` to `Int` except
  /// here, and here it is checked both before and after the multiply.
  private static func milliseconds(_ value: Double) -> Int? {
    guard let seconds = finiteSeconds(value) else { return nil }
    let ms = (seconds * 1000).rounded()
    // A finite value times 1000 can still overflow to infinity.
    guard ms.isFinite, ms >= 0, ms <= 1_000_000_000_000 else { return nil }
    return Int(ms)
  }
}
