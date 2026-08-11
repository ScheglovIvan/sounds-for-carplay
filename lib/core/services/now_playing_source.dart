/// Platform-selected access to the SYSTEM now-playing item.
///
/// Reading the system player is a device-only integration, so the web preview
/// build gets the stub (which reports "nothing playing") and never polls a
/// native side that isn't there. Deep links and the `/#/screen/<id>` preview
/// routes keep working unchanged.
export 'now_playing_source_stub.dart'
    if (dart.library.io) 'now_playing_source_device.dart';
