#
# Local plugin: iOS system music player (MPMusicPlayerController) — now-playing
# metadata plus transport.
#
Pod::Spec.new do |s|
  s.name             = 'system_music'
  s.version          = '0.0.1'
  s.summary          = 'Reads and controls the iOS system music player.'
  s.description      = <<-DESC
Now-playing metadata (title, artist, album, artwork, duration, elapsed time) and
play / pause / next / previous on MPMusicPlayerController.systemMusicPlayer, so
the app can mirror and control whatever the Apple Music app is playing. Every
floating-point value from MediaPlayer is checked for finiteness before it is
converted — currentPlaybackTime is NaN in normal states.
                       DESC
  s.homepage         = 'https://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Drivana' => 'dev@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'
  s.frameworks = 'MediaPlayer'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
