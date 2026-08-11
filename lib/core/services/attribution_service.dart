import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:tenjin_plugin/tenjin_sdk.dart';

import 'apphud_service.dart';

/// Install/event attribution via Tenjin (values from `attribution_config.json`).
///
/// MEASUREMENT ONLY — this app serves no ads and contains no ad SDK. Traffic
/// sources, campaigns and creatives are connected in the Tenjin dashboard and
/// are never named in the app.
///
/// Ordering matters and follows Apple's rules: ATT is requested only once the
/// app is foregrounded and the first frame is on screen (see
/// `Screen_splash.initState`), then Tenjin is initialized, opted in/out
/// according to the ATT answer, and connected. Finally the IDFA is handed to
/// Apphud so a purchase ties back to the campaign that drove the install.
class AttributionService {
  AttributionService._();

  /// SDK key from `attribution_config.json`.
  static const String _sdkKey = 'SWWT2FOKER6B4QXFKERYFPS1S17TKZGU';

  /// The all-zero IDFA iOS hands back when tracking is not authorized.
  static const String _zeroIdfa = '00000000-0000-0000-0000-000000000000';

  static bool _started = false;

  /// Tenjin + ATT are iOS/Android only.
  static bool get _isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  /// Request ATT and wire up attribution. Call AFTER the first frame is
  /// visible. Safe to call more than once; guarded so it can never crash the
  /// app (a no-op on unsupported platforms or an empty key).
  static Future<void> start() async {
    if (_started || !_isSupportedPlatform || _sdkKey.isEmpty) return;
    _started = true;

    TrackingStatus status = TrackingStatus.notDetermined;
    try {
      // 1. The real iOS App Tracking Transparency dialog
      //    (NSUserTrackingUsageDescription — see ios_permissions.json).
      status = await AppTrackingTransparency.requestTrackingAuthorization();
    } catch (e) {
      debugPrint('[attribution] ATT request failed: $e');
    }

    try {
      // 2-4. Initialize Tenjin, honour the ATT answer, then connect.
      //      `initialize(sdkKey:)` is the current API — `init(apiKey:)` is the
      //      deprecated one and is gone in the pinned plugin version.
      TenjinSDK.instance.initialize(sdkKey: _sdkKey);
      if (status == TrackingStatus.authorized) {
        TenjinSDK.instance.optIn();
      } else {
        TenjinSDK.instance.optOut();
      }
      TenjinSDK.instance.connect();
    } catch (e) {
      debugPrint('[attribution] tenjin init failed: $e');
    }

    try {
      // 5. Tie purchases to the campaign: hand the IDFA to Apphud. Only a real
      //    identifier is passed — never the all-zero placeholder.
      final String idfa =
          await AppTrackingTransparency.getAdvertisingIdentifier();
      if (idfa.isNotEmpty && idfa != _zeroIdfa) {
        await ApphudService.setAdvertisingIdentifier(idfa);
      }
    } catch (e) {
      debugPrint('[attribution] idfa handoff failed: $e');
    }

    // 6. Apple Search Ads attribution (iOS).
    await ApphudService.collectSearchAdsAttribution();
  }

  /// Report a purchase that just SUCCEEDED through Apphud to Tenjin, so revenue
  /// can be attributed back to the campaign/creative that drove the install.
  ///
  /// The two SDKs run independently (no paid server-side bridge), so the app
  /// forwards the sale itself. Values come from the Apphud product that was
  /// actually bought, so the reported amount matches what the store charged.
  ///
  /// CRITICAL — call this EXACTLY ONCE per successful purchase, from the
  /// purchase-result handler only ([ApphudService.purchase]). Never on app
  /// start, never on a `hasPremiumAccess()` re-check, never on restore and never
  /// from a widget rebuild: duplicate sends inflate revenue and corrupt ROAS per
  /// creative. Restores are deliberately NOT reported — the original purchase
  /// already was.
  static void reportPurchase({
    required String productId,
    required String currencyCode,
    required double unitPrice,
    required bool isSubscription,
  }) {
    if (!_isSupportedPlatform || _sdkKey.isEmpty) return;
    if (productId.isEmpty || currencyCode.isEmpty || unitPrice <= 0) {
      // Without a real price/currency from the store there is nothing honest to
      // report — stay silent rather than send a wrong amount.
      debugPrint('[attribution] purchase not reported: incomplete store data');
      return;
    }

    try {
      // Called through `dynamic` so a plugin signature change degrades to a
      // caught runtime no-op instead of breaking the build; revenue reporting
      // must never be able to take the app down after a real purchase.
      final dynamic tenjin = TenjinSDK.instance;
      if (isSubscription) {
        tenjin.subscriptionWithStoreKit(productId, currencyCode, unitPrice);
      } else {
        tenjin.transaction(productId, currencyCode, 1, unitPrice);
      }
    } catch (e) {
      debugPrint('[attribution] purchase report failed: $e');
    }
  }
}
