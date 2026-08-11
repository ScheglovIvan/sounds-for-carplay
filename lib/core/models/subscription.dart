import 'package:flutter/foundation.dart';

/// Billing period of a subscription product.
///
/// Always resolved at runtime from the store product attached to the Apphud
/// product — the app never declares which periods exist.
enum BillingPeriod {
  weekly('week', 1.0),
  monthly('month', 4.345),
  quarterly('3 months', 13.04),
  semiAnnual('6 months', 26.09),
  annual('year', 52.18);

  const BillingPeriod(this.unit, this.weeks);

  /// Period label used in price framing ("per $unit").
  final String unit;

  /// Approximate weeks in one period, used to derive a "/wk" figure from the
  /// real store price.
  final double weeks;
}

/// A purchasable subscription product.
///
/// Instances are ONLY ever built from a live Apphud product
/// ([SubscriptionProduct.fromApphud]): the app ships no product catalog and
/// hardcodes no price or product id, so a product added later in the Apphud
/// dashboard appears in the paywall without an app update.
@immutable
class SubscriptionProduct {
  const SubscriptionProduct({
    required this.vendorProductId,
    required this.title,
    required this.price,
    this.apphudProduct,
    this.period,
    this.rawPrice,
    this.currencyCode,
    this.pricePerWeek,
    this.discountBadge,
    this.subtitle,
    this.introOfferLabel,
  });

  /// The store product id, as reported by Apphud.
  final String vendorProductId;

  /// User-facing plan title, derived from the store product (or its period).
  final String title;

  /// Localized store price exactly as the store reports it, e.g. `$39.99`.
  final String price;

  /// Numeric price, when the store product exposed one — used to derive the
  /// per-week framing and the relative "% OFF" badge.
  final double? rawPrice;

  /// ISO currency code the store quoted the price in (e.g. `USD`), used when
  /// reporting revenue so the amount always carries its real currency.
  final String? currencyCode;

  /// Subscription period resolved from the store product, when available.
  final BillingPeriod? period;

  /// Wording for the introductory offer this product carries, e.g.
  /// `3-day free trial`. Null when the store product has no intro offer.
  ///
  /// Having an offer is NOT the same as being allowed one: whether this user is
  /// actually eligible is answered by
  /// `Apphud.checkEligibilityForIntroductoryOffer()` at runtime
  /// ([ApphudService.introEligibility]), and the paywall only shows this label
  /// once that comes back true.
  final String? introOfferLabel;

  /// True when the store product advertises an intro offer / free trial at all.
  bool get hasIntroOffer => introOfferLabel != null;

  /// Whether this is a renewing subscription (as opposed to a one-time buy),
  /// which decides how a purchase is reported to Tenjin.
  bool get isSubscription => period != null;

  /// Per-week framing derived from [rawPrice] and [period].
  final String? pricePerWeek;

  /// Savings badge computed by comparing this product's per-week cost against
  /// the other products in the same placement — never a hardcoded claim.
  final String? discountBadge;

  /// Supporting line under the title (billing cadence).
  final String? subtitle;

  /// The raw Apphud product this was built from. Handed straight back to
  /// `Apphud.purchase(product: ...)` so the buy always targets the live object.
  final Object? apphudProduct;

  /// True once a real store price was attached (false in a preview where
  /// StoreKit is unavailable).
  bool get hasStorePrice => rawPrice != null;

  /// Effective cost per week, used to rank plans by value.
  double? get weeklyCost {
    final double? raw = rawPrice;
    final BillingPeriod? p = period;
    if (raw == null || p == null) return null;
    return raw / p.weeks;
  }

  SubscriptionProduct copyWith({
    String? discountBadge,
    String? subtitle,
  }) {
    return SubscriptionProduct(
      vendorProductId: vendorProductId,
      title: title,
      price: price,
      rawPrice: rawPrice,
      currencyCode: currencyCode,
      period: period,
      pricePerWeek: pricePerWeek,
      discountBadge: discountBadge ?? this.discountBadge,
      subtitle: subtitle ?? this.subtitle,
      introOfferLabel: introOfferLabel,
      apphudProduct: apphudProduct,
    );
  }

  /// Build a display product from a live Apphud product.
  ///
  /// Everything shown to the user (id, title, price, period) comes from the
  /// Apphud/StoreKit object. Every field access is defensive: a store product
  /// that does not expose a given field simply leaves it null rather than
  /// throwing, so an unfamiliar product still renders and stays buyable.
  factory SubscriptionProduct.fromApphud(dynamic product) {
    final String id = _string(() => product.productId) ?? '';
    final dynamic store = _value(() => product.skProduct) ??
        _value(() => product.productDetails);

    final double? raw = _price(store);
    final BillingPeriod? period = _period(store);
    final String? symbol = _string(() => store.priceLocale.currencySymbol);

    // Prefer a price string the store already formatted for the locale; else
    // compose one from the numeric price + the locale's currency symbol.
    final String display = _string(() => store.formattedPrice) ??
        (raw != null ? '${symbol ?? ''}${raw.toStringAsFixed(2)}' : '—');

    final String title = _string(() => store.localizedTitle) ??
        _string(() => store.title) ??
        _string(() => product.name) ??
        (period != null ? _periodTitle(period) : id);

    String? perWeek;
    if (raw != null && period != null && period != BillingPeriod.weekly) {
      perWeek = '${symbol ?? ''}${(raw / period.weeks).toStringAsFixed(2)}';
    }

    return SubscriptionProduct(
      vendorProductId: id,
      title: title,
      price: display,
      rawPrice: raw,
      currencyCode: _string(() => store.priceLocale.currencyCode) ??
          _string(() => store.priceCurrencyCode),
      period: period,
      pricePerWeek: perWeek,
      subtitle: period == null ? null : 'Billed every ${period.unit}',
      introOfferLabel: _introOfferLabel(store),
      apphudProduct: product as Object?,
    );
  }

  /// Add a relative savings badge to each product by comparing per-week cost
  /// against the most expensive plan in the same placement. Purely derived from
  /// the real store prices, so it stays honest as dashboard pricing changes.
  static List<SubscriptionProduct> annotate(List<SubscriptionProduct> products) {
    final List<double> weekly = <double>[
      for (final SubscriptionProduct p in products)
        if (p.weeklyCost != null) p.weeklyCost!,
    ];
    if (weekly.length < 2) return products;

    final double baseline = weekly.reduce((a, b) => a > b ? a : b);
    final List<SubscriptionProduct> out = <SubscriptionProduct>[];
    for (final SubscriptionProduct p in products) {
      final double? cost = p.weeklyCost;
      if (cost == null || cost >= baseline) {
        out.add(p);
        continue;
      }
      final int off = (100 * (1 - cost / baseline)).round();
      out.add(off >= 5 ? p.copyWith(discountBadge: '$off% OFF') : p);
    }
    return out;
  }

  static String _periodTitle(BillingPeriod period) {
    switch (period) {
      case BillingPeriod.weekly:
        return 'Weekly';
      case BillingPeriod.monthly:
        return 'Monthly';
      case BillingPeriod.quarterly:
        return 'Quarterly';
      case BillingPeriod.semiAnnual:
        return '6 Months';
      case BillingPeriod.annual:
        return 'Annual';
    }
  }

  /// Describe the store product's introductory offer, when it has one.
  ///
  /// Read straight off StoreKit's `introductoryPrice` (Android: the offer on the
  /// subscription plan), so the wording matches the offer Apple would actually
  /// apply. Returns null when the product carries no intro offer — the paywall
  /// then never mentions a trial for it.
  static String? _introOfferLabel(dynamic store) {
    final dynamic intro = _value(() => store.introductoryPrice);
    if (intro == null) return null;

    final dynamic p = _value(() => intro.subscriptionPeriod);
    final String unit = '${_value(() => p.unit)}'.toLowerCase();
    final dynamic countRaw = _value(() => p.numberOfUnits);
    final int count = countRaw is num ? countRaw.toInt() : 1;
    final dynamic periodsRaw = _value(() => intro.numberOfPeriods);
    final int periods = periodsRaw is num ? periodsRaw.toInt() : 1;
    final int total = count * (periods < 1 ? 1 : periods);

    String? span;
    for (final String name in const <String>['day', 'week', 'month', 'year']) {
      if (unit.contains(name)) {
        span = '$total-$name${total == 1 ? '' : 's'}';
        break;
      }
    }

    // Payment mode tells free trial apart from a discounted intro price.
    final String mode = '${_value(() => intro.paymentMode)}'.toLowerCase();
    final double? introPrice = _price(intro);
    final bool isFree =
        mode.contains('free') || mode.contains('trial') || introPrice == 0;

    if (isFree) {
      return span == null ? 'Free trial' : '$span free trial';
    }
    final String? formatted = _string(() => intro.formattedPrice);
    if (formatted == null) return span == null ? null : 'Intro offer for $span';
    return span == null
        ? 'Intro price $formatted'
        : '$formatted for your first $span';
  }

  /// Read a numeric price off a store product, tolerating num / String forms.
  static double? _price(dynamic store) {
    final dynamic v = _value(() => store.price);
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    // Android exposes the amount in micros.
    final dynamic micros = _value(() => store.priceAmountMicros);
    if (micros is num) return micros.toDouble() / 1000000.0;
    return null;
  }

  /// Resolve the subscription period from the store product's period object
  /// (`unit` + `numberOfUnits`), which is how StoreKit describes it.
  static BillingPeriod? _period(dynamic store) {
    final dynamic p = _value(() => store.subscriptionPeriod);
    if (p == null) return null;
    final String unit = '${_value(() => p.unit)}'.toLowerCase();
    final dynamic countRaw = _value(() => p.numberOfUnits);
    final int count = countRaw is num ? countRaw.toInt() : 1;

    if (unit.contains('week')) {
      return count >= 52 ? BillingPeriod.annual : BillingPeriod.weekly;
    }
    if (unit.contains('month')) {
      if (count >= 12) return BillingPeriod.annual;
      if (count >= 6) return BillingPeriod.semiAnnual;
      if (count >= 3) return BillingPeriod.quarterly;
      return BillingPeriod.monthly;
    }
    if (unit.contains('year')) return BillingPeriod.annual;
    if (unit.contains('day')) {
      return count >= 7 ? BillingPeriod.weekly : null;
    }
    return null;
  }

  /// Read [get] off a dynamic store object, returning null instead of throwing
  /// when the field does not exist on this platform's product type.
  static dynamic _value(dynamic Function() get) {
    try {
      return get();
    } catch (_) {
      return null;
    }
  }

  static String? _string(dynamic Function() get) {
    final dynamic v = _value(get);
    if (v == null) return null;
    final String s = '$v'.trim();
    return s.isEmpty ? null : s;
  }
}

/// Resolved PRO entitlement.
///
/// Only ever produced from `Apphud.hasPremiumAccess()` — there is no local
/// entitlement flag and nothing here is persisted to disk.
@immutable
class Entitlement {
  const Entitlement({
    required this.isActive,
    this.accessLevelId = 'premium',
    this.productId,
    this.renewsAt,
    this.source = 'apphud',
  });

  /// A free (inactive) entitlement.
  static const Entitlement free = Entitlement(isActive: false);

  final bool isActive;
  final String accessLevelId;

  /// The store product id backing the active entitlement, if Apphud reported
  /// one with the purchase.
  final String? productId;

  /// Auto-renewal date for the active subscription.
  final DateTime? renewsAt;

  /// Where the entitlement was resolved from (apphud / restore).
  final String source;

  Entitlement copyWith({
    bool? isActive,
    String? productId,
    DateTime? renewsAt,
    String? source,
  }) {
    return Entitlement(
      isActive: isActive ?? this.isActive,
      accessLevelId: accessLevelId,
      productId: productId ?? this.productId,
      renewsAt: renewsAt ?? this.renewsAt,
      source: source ?? this.source,
    );
  }
}
