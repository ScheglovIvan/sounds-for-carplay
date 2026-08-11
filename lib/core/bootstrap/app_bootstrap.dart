import 'package:flutter/foundation.dart';

import '../app_state.dart';
import '../services/apphud_service.dart';

/// One-time app initialization run on the splash screen.
///
/// The real third-party SDKs are wired elsewhere and are NOT stubbed:
///   * subscriptions -> `ApphudService` (started in `main()`),
///   * attribution   -> `AttributionService` (ATT + Tenjin, started after the
///     first frame so Apple's foreground requirement is met).
///
/// What remains here is the per-launch work the splash waits on: hydrating
/// persisted state and re-resolving the PRO entitlement from Apphud.
class AppBootstrap {
  AppBootstrap._();

  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  /// Run launch initialization. Safe to call more than once.
  static Future<void> initialize() async {
    if (_initialized) return;
    // Idempotent load of theme / slots / preferences.
    await AppState.load();
    // Re-read the entitlement from Apphud — the single source of truth — so the
    // app opens unlocked for a subscriber and locked for a lapsed one.
    await ApphudService.refreshPremium();
    _initialized = true;
    debugPrint('[bootstrap] ready; pro=${AppState.isPro.value}');
  }
}
