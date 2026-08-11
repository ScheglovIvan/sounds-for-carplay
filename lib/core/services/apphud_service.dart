import 'package:flutter/foundation.dart';
import 'package:apphud/apphud.dart';

import '../app_state.dart';
import '../models/subscription.dart';
import 'attribution_service.dart';
import 'entitlement_service.dart';

/// How a paywall product load ended, so the UI can show the right state instead
/// of an empty screen.
enum PaywallStatus {
  /// Products loaded and the placement offers at least one.
  ready,

  /// Apphud answered, but the placement returned no products (dashboard not
  /// configured yet, or products not approved in App Store Connect).
  empty,

  /// The store is not available on this platform (web / desktop preview).
  unavailable,

  /// Apphud failed to answer (offline, bad key, SDK error).
  error,
}

/// Result of loading the paywall's products from Apphud.
@immutable
class PaywallLoad {
  const PaywallLoad(this.status, this.products, {this.paywall});

  final PaywallStatus status;
  final List<SubscriptionProduct> products;

  /// The raw `ApphudPaywall` the products came from. Handed back to
  /// `Apphud.paywallShown()` when the paywall becomes visible so Apphud records
  /// the impression that its analytics and A/B tests are built on.
  final Object? paywall;

  bool get hasProducts => products.isNotEmpty;

  /// A short, honest message for the non-[PaywallStatus.ready] states. The
  /// paywall shows this in place of the plan list so it is never blank.
  String get message {
    switch (status) {
      case PaywallStatus.ready:
        return '';
      case PaywallStatus.empty:
        return 'No subscription plans are available right now. '
            'Please try again in a moment.';
      case PaywallStatus.unavailable:
        return 'Subscriptions are only available in the iOS app. '
            'Everything free stays fully usable here.';
      case PaywallStatus.error:
        return "We couldn't reach the store. Check your connection and "
            'try again.';
    }
  }
}

/// Live Apphud wiring (values from `apphud_config.json`).
///
/// This is the REAL store path: every buy / restore / premium-unlock goes
/// through Apphud — there is no local "succeeds anyway" stand-in and no local
/// flag. PRO is granted only when `Apphud.hasPremiumAccess()` is true, which is
/// the single source of truth for entitlement across the app. Apphud
/// auto-detects the StoreKit sandbox vs production, so purchases are testable in
/// the sandbox without a live App Store link.
///
/// The paywall products come from `Apphud.placements()` at runtime, so products
/// added later in the Apphud dashboard appear without an app update — no price
/// or product id is hardcoded anywhere in the UI.
class ApphudService {
  ApphudService._();

  /// SDK key from `apphud_config.json`.
  static const String _apiKey = 'appstr_DFwYTGsV7jRSc4z7FVjgkWkZXttD4uc8Bjs';

  /// Placement identifier from `apphud_config.json` that carries the paywall.
  static const String _placementId = 'main_drivana';

  static bool _started = false;

  /// True once [Apphud.start] has succeeded on a supported platform. While
  /// false, purchases are unavailable and callers must not grant PRO.
  static bool get isStarted => _started;

  /// Apphud's Flutter SDK only supports iOS and Android natively.
  static bool get _isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  /// Start the Apphud SDK. Safe to call from `main()`: it is a no-op on
  /// unsupported platforms or when the key is empty, and never throws.
  static Future<void> start() async {
    if (_started || !_isSupportedPlatform || _apiKey.isEmpty) return;
    try {
      await Apphud.start(apiKey: _apiKey);
      _started = true;
    } catch (e) {
      debugPrint('[apphud] start failed: $e');
    }
  }

  /// The last load's result. NEVER used to render a price — only for the
  /// synchronous, price-free lookups below (e.g. naming the active plan).
  static PaywallLoad? _cache;

  /// The last successfully loaded products, for synchronous lookups (e.g. the
  /// Membership screen naming the active plan).
  static List<SubscriptionProduct> get cachedProducts =>
      _cache?.products ?? const <SubscriptionProduct>[];

  static SubscriptionProduct? cachedProductById(String productId) {
    for (final SubscriptionProduct p in cachedProducts) {
      if (p.vendorProductId == productId) return p;
    }
    return null;
  }

  /// Load the configured placement's paywall products from Apphud.
  ///
  /// ALWAYS re-reads the placement from the SDK — there is deliberately no
  /// "return what we loaded at startup" shortcut. A storefront can change
  /// (territory, price tier, a dashboard edit) after the first fetch, and a
  /// paywall that renders the startup price while the store charges the current
  /// one is exactly the bug this avoids. Every paywall calls this as it is
  /// shown, and [refreshProducts] calls it again on app resume.
  ///
  /// [refresh] is kept for callers that want to be explicit (a Retry button);
  /// it makes no difference — the load is never served from a cache.
  static Future<PaywallLoad> loadPaywall({bool refresh = false}) async {
    if (!_started) {
      return const PaywallLoad(
        PaywallStatus.unavailable,
        <SubscriptionProduct>[],
      );
    }

    try {
      final List<dynamic> placements = await Apphud.placements();
      dynamic placement;
      for (final dynamic p in placements) {
        if (p.identifier == _placementId) {
          placement = p;
          break;
        }
      }
      // Fall back to the first placement so a renamed placement still shows
      // plans rather than an empty paywall.
      placement ??= placements.isNotEmpty ? placements.first : null;

      final dynamic paywall = placement?.paywall;
      final List<dynamic> raw =
          (paywall?.products as List<dynamic>?) ?? const <dynamic>[];

      // Only products that carry a REAL store price are ever handed to the UI.
      // A product whose StoreKit/BillingClient object hasn't loaded has no
      // trustworthy price, and the paywall must show a loading/empty state
      // rather than a placeholder the store would not honour.
      final List<SubscriptionProduct> priced = <SubscriptionProduct>[
        for (final dynamic p in raw) SubscriptionProduct.fromApphud(p),
      ].where((SubscriptionProduct p) => p.hasStorePrice).toList();
      // Badges and "/wk" figures are derived here, from this same freshly
      // loaded set, so they can never disagree with the headline price.
      final List<SubscriptionProduct> products =
          SubscriptionProduct.annotate(priced);

      final PaywallLoad load = PaywallLoad(
        products.isEmpty ? PaywallStatus.empty : PaywallStatus.ready,
        products,
        paywall: paywall as Object?,
      );
      _cache = load;
      return load;
    } catch (e) {
      debugPrint('[apphud] placements failed: $e');
      return const PaywallLoad(PaywallStatus.error, <SubscriptionProduct>[]);
    }
  }

  /// Re-read the placement's products from the store.
  ///
  /// Called when the app returns to the foreground: the user may have changed
  /// their App Store territory / storefront while away, which moves every
  /// product to a different price tier. Refreshing here means the next paywall
  /// opens with prices that match what the store will actually charge.
  static Future<void> refreshProducts() async {
    if (!_started) return;
    await loadPaywall(refresh: true);
  }

  /// Tell Apphud a paywall is on screen. Without this Apphud records no
  /// impressions, so conversion rates and paywall A/B tests stay empty.
  ///
  /// Pass the `paywall` from the placement that produced the products. Call once
  /// per presentation — the paywall screens do this from `initState` once their
  /// load resolves, never from `build`.
  static Future<void> paywallShown(Object? paywall) async {
    if (!_started || paywall == null) return;
    try {
      await Apphud.paywallShown(paywall as dynamic);
    } catch (e) {
      debugPrint('[apphud] paywallShown failed: $e');
    }
  }

  /// Whether this user would actually get [product]'s introductory offer / free
  /// trial, per `Apphud.checkEligibilityForIntroductoryOffer()`.
  ///
  /// Returns false when the product has no offer, when Apphud can't answer, or
  /// when the user has already used one — the paywall then shows the plain price
  /// rather than promising a trial Apple would not grant.
  static Future<bool> introEligibility(SubscriptionProduct product) async {
    if (!_started || !product.hasIntroOffer) return false;
    final Object? live = product.apphudProduct;
    if (live == null) return false;
    try {
      final dynamic eligible =
          await Apphud.checkEligibilityForIntroductoryOffer(
        productId: product.vendorProductId,
      );
      return eligible == true;
    } catch (e) {
      debugPrint('[apphud] intro eligibility check failed: $e');
      return false;
    }
  }

  /// Buy [product] through Apphud and re-resolve PRO from
  /// `Apphud.hasPremiumAccess()` afterwards.
  static Future<EntitlementResult> purchase(SubscriptionProduct product) async {
    if (!_started) return EntitlementResult.failed;
    try {
      final Object? live = product.apphudProduct;
      final dynamic result = live != null
          ? await Apphud.purchase(product: live as dynamic)
          : await Apphud.purchase(productId: product.vendorProductId);

      // Entitlement is re-read from Apphud, never inferred from the call.
      if (await _syncPremium(productId: product.vendorProductId)) {
        // The ONE place a purchase is reported to Tenjin: a confirmed, brand-new
        // sale. Restores and premium re-checks deliberately do not report — a
        // duplicate send would inflate revenue and corrupt ROAS per creative.
        _reportRevenue(product);
        return EntitlementResult.success;
      }
      final dynamic error = _read(() => result.error);
      if (error != null && _isCancellation(error)) {
        return EntitlementResult.cancelled;
      }
      return EntitlementResult.failed;
    } catch (e) {
      debugPrint('[apphud] purchase failed: $e');
      return EntitlementResult.failed;
    }
  }

  /// Restore previous purchases and re-resolve PRO from Apphud.
  static Future<EntitlementResult> restore() async {
    if (!_started) return EntitlementResult.nothingToRestore;
    try {
      await Apphud.restorePurchases();
      if (await _syncPremium(source: 'restore')) {
        return EntitlementResult.success;
      }
      return EntitlementResult.nothingToRestore;
    } catch (e) {
      debugPrint('[apphud] restore failed: $e');
      return EntitlementResult.failed;
    }
  }

  /// Re-check the entitlement against Apphud. Called at launch, on app resume
  /// and after every purchase/restore, so a returning subscriber opens already
  /// unlocked and a lapsed one is downgraded.
  static Future<void> refreshPremium() async {
    if (!_started) return;
    await _syncPremium();
  }

  /// Pass the IDFA to Apphud so a purchase ties back to the campaign that drove
  /// the install (see `AttributionService`).
  static Future<void> setAdvertisingIdentifier(String idfa) async {
    if (!_started || idfa.isEmpty) return;
    try {
      await Apphud.setAdvertisingIdentifier(idfa);
    } catch (e) {
      debugPrint('[apphud] setAdvertisingIdentifier failed: $e');
    }
  }

  /// Collect Apple Search Ads attribution (iOS).
  static Future<void> collectSearchAdsAttribution() async {
    if (!_started) return;
    try {
      await Apphud.collectSearchAdsAttribution();
    } catch (e) {
      debugPrint('[apphud] collectSearchAdsAttribution failed: $e');
    }
  }

  /// Read `Apphud.hasPremiumAccess()` — the single source of truth — and push
  /// the result into [AppState]. Returns whether PRO is active.
  static Future<bool> _syncPremium({
    String? productId,
    String source = 'apphud',
  }) async {
    try {
      final bool active = await Apphud.hasPremiumAccess();
      // Keep the known plan id across a plain re-check, which doesn't carry one.
      final String? knownId = AppState.entitlement.value.productId;
      AppState.applyEntitlement(
        Entitlement(
          isActive: active,
          productId: active ? (productId ?? knownId) : null,
          source: source,
        ),
      );
      return active;
    } catch (e) {
      debugPrint('[apphud] hasPremiumAccess failed: $e');
      return false;
    }
  }

  /// Forward a just-confirmed sale to Tenjin, using the price/currency/id of the
  /// Apphud product that was actually bought so the reported amount matches the
  /// real charge. Called from [purchase] only — see [AttributionService.
  /// reportPurchase] for why exactly-once matters.
  static void _reportRevenue(SubscriptionProduct product) {
    final double? price = product.rawPrice;
    final String? currency = product.currencyCode;
    if (price == null || currency == null) return;
    AttributionService.reportPurchase(
      productId: product.vendorProductId,
      currencyCode: currency,
      unitPrice: price,
      isSubscription: product.isSubscription,
    );
  }

  /// StoreKit reports a user-cancelled payment as error code 2; also match a
  /// "cancel" message defensively across platforms.
  static bool _isCancellation(dynamic error) {
    if (_read(() => error.code) == 2) return true;
    return '${_read(() => error.message)}'.toLowerCase().contains('cancel');
  }

  static dynamic _read(dynamic Function() get) {
    try {
      return get();
    } catch (_) {
      return null;
    }
  }
}
