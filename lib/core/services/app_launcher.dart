import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Small helper that opens a system URL scheme (used to open Apple Music).
class AppLauncher {
  AppLauncher._();

  /// Attempt to open [uri]; returns whether it launched.
  static Future<bool> open(Uri uri) async {
    if (kIsWeb) return false;
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // ignore — a launch attempt still follows below.
    }
    // iOS gates `canOpenURL` (what canLaunchUrl asks) behind
    // LSApplicationQueriesSchemes, so it answers false for app schemes like
    // `music://` that we cannot declare there. Actually OPENING a URL is not
    // gated, so try it before reporting failure.
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> openRaw(String url) => open(Uri.parse(url));

  static Future<bool> music() => open(Uri.parse('music://'));
}
