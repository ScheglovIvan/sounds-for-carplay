import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/sound.dart';
import '../router/app_router.dart';
import 'entitlement_service.dart';

/// UI-facing orchestration for the PRO purchase & entitlement flow.
///
/// Wraps the Apphud-backed [EntitlementService] with paywall presentation
/// and user feedback so every screen drives purchase / restore / premium-gating
/// the SAME way:
///   * [openPaywall]   — surface the standard or special-offer placement.
///   * [ensurePro]     — gate a premium action, routing to the paywall if free.
///   * [ensureCanUse]  — gate selecting a specific (possibly premium) [Sound].
///   * [restore]       — run a restore and report the outcome via a snackbar.
///
/// Screens should never call [EntitlementService] directly for these flows —
/// route through here so gating and feedback stay consistent app-wide.
class PurchaseFlow {
  PurchaseFlow._();

  /// Route to a paywall placement: the standard "Get Unlimited Access" wall
  /// (`0002`) by default, or the discounted `paywall_special` when [special].
  static Future<void> openPaywall(BuildContext context, {bool special = false}) {
    return AppRouter.go<void>(context, special ? 'paywall_special' : '0002');
  }

  /// Gate a premium feature. Returns immediately if the user already holds PRO;
  /// otherwise presents the paywall and reports whether PRO was granted while
  /// it was open (purchase or restore).
  static Future<bool> ensurePro(BuildContext context) async {
    if (AppState.isPro.value) return true;
    await openPaywall(context);
    return AppState.isPro.value;
  }

  /// Gate selecting [sound]. Free sounds always pass; a premium sound requires
  /// PRO, so a free user is sent to the paywall first. Returns true when the
  /// sound may be used (i.e. it's free, the user is PRO, or they just upgraded).
  static Future<bool> ensureCanUse(BuildContext context, Sound sound) async {
    if (!EntitlementService.instance.isSoundLocked(sound)) return true;
    return ensurePro(context);
  }

  /// Restore a previous purchase and surface the result as a snackbar. Returns
  /// true when an active entitlement was restored.
  static Future<bool> restore(BuildContext context) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Checking your account for past purchases…'),
          behavior: SnackBarBehavior.floating,
        ),
      );

    final EntitlementResult result =
        await EntitlementService.instance.restore();
    messenger.hideCurrentSnackBar();

    switch (result) {
      case EntitlementResult.success:
        _snack(messenger, 'Your Premium access has been restored.');
        return true;
      case EntitlementResult.nothingToRestore:
        _snack(messenger, 'No previous purchase found to restore.');
        return false;
      case EntitlementResult.failed:
      case EntitlementResult.cancelled:
        _snack(messenger, "We couldn't restore right now. Please try again.");
        return false;
    }
  }

  static void _snack(ScaffoldMessengerState messenger, String message) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
