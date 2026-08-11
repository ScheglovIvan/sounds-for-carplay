import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../app_state.dart';

/// Real notification authorization.
///
/// The app's priming card explains WHY alerts help (break nudges, arrival cue
/// confirmations); this service then triggers the ACTUAL iOS
/// `UNUserNotificationCenter` authorization prompt through `permission_handler`
/// — it never just flips a local flag. iOS needs no Info.plist usage-description
/// key for notifications, so `ios_permissions.json` is unchanged by this.
///
/// [AppState.notificationsEnabled] mirrors the OS answer so the UI can show the
/// granted state, and is re-read on entry so a change made in iOS Settings is
/// picked up.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  /// Ask the OS for permission (the real system dialog on the first call).
  ///
  /// Once the user has answered, iOS never shows the prompt again — so if we
  /// already hold a permanent denial we send them to the app's Settings page,
  /// which is the only place the decision can still be changed. Returns whether
  /// notifications are authorized afterwards.
  Future<bool> request() async {
    if (kIsWeb) return false;
    try {
      PermissionStatus status = await Permission.notification.status;
      if (status.isPermanentlyDenied) {
        await openAppSettings();
        status = await Permission.notification.status;
      } else if (!status.isGranted) {
        status = await Permission.notification.request();
      }
      final bool granted = status.isGranted || status.isLimited;
      AppState.setNotificationsEnabled(granted);
      return granted;
    } catch (_) {
      return false;
    }
  }

  /// Re-read the OS state without prompting, so the UI reflects a permission
  /// the user changed in iOS Settings while the app was backgrounded.
  Future<bool> refresh() async {
    if (kIsWeb) return false;
    try {
      final PermissionStatus status = await Permission.notification.status;
      final bool granted = status.isGranted || status.isLimited;
      if (granted != AppState.notificationsEnabled.value) {
        AppState.setNotificationsEnabled(granted);
      }
      return granted;
    } catch (_) {
      return false;
    }
  }
}
