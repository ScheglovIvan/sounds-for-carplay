import 'dart:async';

import 'package:flutter/material.dart';

import 'package:drivana/core/data/legal_links.dart';
import 'package:drivana/core/models/subscription.dart';
import 'package:drivana/core/services/apphud_service.dart';
import 'package:drivana/core/services/entitlement_service.dart';
import 'package:drivana/core/state.dart';
import 'package:drivana/ui/components/components.dart';

/// Discounted special-offer paywall (app_spec id "paywall_special").
///
/// The recovery placement shown when the standard paywall is dismissed (or on a
/// later launch): a single, time-limited best-value plan with a live countdown
/// for urgency.
///
/// The offer is chosen at RUNTIME from the same Apphud placement as the standard
/// paywall — the plan with the lowest real per-week cost — and the struck-through
/// comparison price is the placement's most expensive plan. No product id, price
/// or discount claim is hardcoded, so dashboard pricing changes flow straight
/// through.
///
/// Block order/sizing follows `source/paywall_special.json`; color, type and
/// rounding come from the frozen design system. Copy is paraphrased and icons
/// use the app's own rounded Material set per the anti-clone rules.
class Screen_paywall_special extends StatefulWidget {
  const Screen_paywall_special({super.key});

  @override
  State<Screen_paywall_special> createState() => _Screen_paywall_specialState();
}

class _Screen_paywall_specialState extends State<Screen_paywall_special>
    with WidgetsBindingObserver {
  /// Countdown seconds remaining (10:00) — refreshes the urgency banner.
  static const int _initialSeconds = 10 * 60;
  int _remaining = _initialSeconds;
  Timer? _ticker;

  bool _busy = false;
  bool _loading = true;

  PaywallLoad? _load;

  /// The offered plan: the placement's best per-week value, resolved at runtime.
  SubscriptionProduct? _offer;

  /// The placement's priciest plan, struck through next to [_offer] so the
  /// saving shown is a real one. Null when there is nothing to compare against.
  SubscriptionProduct? _compareAt;

  /// The offer's intro/trial wording, set only once Apphud confirmed this user
  /// is eligible for it. Null means they'd be charged now, so only the real
  /// price is shown.
  String? _trialLabel;

  /// Guards `Apphud.paywallShown()` to one call per presentation.
  bool _impressionReported = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Fetched fresh right before the offer is shown, so the price on screen is
    // the price the store will charge.
    _loadProducts();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remaining > 0) _remaining -= 1;
      });
    });
  }

  /// Re-read the offer after a spell in the background — the storefront may
  /// have changed while the app was away.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_busy) {
      _loadProducts(refresh: true);
    }
  }

  Future<void> _loadProducts({bool refresh = false}) async {
    // Only spin when there is nothing to show yet; a background refresh must
    // not flash over a price that is already right.
    if (refresh && _offer == null && !_loading) {
      setState(() => _loading = true);
    }
    final PaywallLoad load = await ApphudService.loadPaywall(refresh: refresh);
    if (!mounted) return;

    // Rank the placement's plans by their REAL per-week cost: the cheapest is
    // the offer, the dearest is the struck-through comparison.
    SubscriptionProduct? best;
    double? bestCost;
    SubscriptionProduct? dearest;
    double? dearestCost;
    for (final SubscriptionProduct p in load.products) {
      best ??= p;
      final double? cost = p.weeklyCost;
      if (cost == null) continue;
      if (bestCost == null || cost < bestCost) {
        best = p;
        bestCost = cost;
      }
      if (dearestCost == null || cost > dearestCost) {
        dearest = p;
        dearestCost = cost;
      }
    }

    final SubscriptionProduct? offer = best;
    final SubscriptionProduct? compare = dearest;

    setState(() {
      _load = load;
      _loading = false;
      _offer = offer;
      // Only show a comparison when it's a genuinely different, dearer plan.
      _compareAt = (offer != null &&
              compare != null &&
              compare.vendorProductId != offer.vendorProductId)
          ? compare
          : null;
    });

    // Record the impression once per presentation — Apphud's paywall analytics
    // and A/B tests are built on this call.
    if (!_impressionReported && load.paywall != null) {
      _impressionReported = true;
      await ApphudService.paywallShown(load.paywall);
    }

    // Only advertise the intro offer if Apphud says this user would get it.
    final String? trial = offer != null &&
            offer.hasIntroOffer &&
            await ApphudService.introEligibility(offer)
        ? offer.introOfferLabel
        : null;
    if (!mounted) return;
    setState(() => _trialLabel = trial);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  /// CTA copy built from the live product's own price and period.
  /// The trial variant appears ONLY when Apphud confirmed eligibility.
  String _ctaLabel(SubscriptionProduct? offer) {
    if (_loading) return 'Loading your offer…';
    if (offer == null) return 'Offer unavailable';
    final String? trial = _trialLabel;
    if (trial != null) return 'Start your $trial';
    if (!offer.hasStorePrice) return 'Claim this offer';
    final BillingPeriod? period = offer.period;
    return period == null
        ? 'Claim ${offer.price}'
        : 'Claim ${offer.price} per ${period.unit}';
  }

  String get _countdown {
    final int m = _remaining ~/ 60;
    final int s = _remaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _claim() async {
    final SubscriptionProduct? offer = _offer;
    if (_busy || offer == null) return;
    setState(() => _busy = true);
    final EntitlementResult result =
        await EntitlementService.instance.purchase(offer);
    if (!mounted) return;
    setState(() => _busy = false);
    _handleResult(result, purchased: true);
  }

  Future<void> _restore() async {
    if (_busy) return;
    setState(() => _busy = true);
    final EntitlementResult result =
        await EntitlementService.instance.restore();
    if (!mounted) return;
    setState(() => _busy = false);
    _handleResult(result, purchased: false);
  }

  void _handleResult(EntitlementResult result, {required bool purchased}) {
    switch (result) {
      case EntitlementResult.success:
        _goHome();
        break;
      case EntitlementResult.nothingToRestore:
        _toast('No previous purchase found to restore.');
        break;
      case EntitlementResult.cancelled:
        break;
      case EntitlementResult.failed:
        _toast(purchased
            ? 'Purchase could not be completed. Please try again.'
            : 'Restore failed. Please try again.');
        break;
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Decline the offer and continue into the app on the free tier. This is the
  /// terminal onboarding step on the dismissal path, so mark onboarding done.
  void _goHome() {
    AppState.completeOnboarding();
    // The Drive tab (Focus Drive home) is the app's landing screen.
    Navigator.of(context).pushNamedAndRemoveUntil('/0007', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final SubscriptionProduct? offer = _offer;
    // Clear the (full-bleed) top bar that the body extends behind.
    final double topPad = MediaQuery.of(context).padding.top + 56 + 8;

    return AppScaffold(
      extendBodyBehindTopBar: true,
      background: const _OfferBackdrop(),
      topBar: AppTopBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 26),
          color: AppColors.textPrimary,
          onPressed: _busy ? null : _goHome,
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : _restore,
            child: Text(
              'Restore',
              style: text.titleMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: topPad),
                      if (offer?.discountBadge != null)
                        AppBadge(
                          label: offer!.discountBadge!,
                          icon: Icons.local_fire_department_rounded,
                        ),
                      const SizedBox(height: 18),
                      Text(
                        'A one-time deal, just for you',
                        textAlign: TextAlign.center,
                        style: text.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Go Premium at our lowest price yet — this offer '
                        'disappears when the timer runs out.',
                        textAlign: TextAlign.center,
                        style: text.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _CountdownBanner(value: _countdown),
                      const SizedBox(height: 24),
                      if (_loading)
                        const _OfferLoading()
                      else if (offer == null)
                        _OfferUnavailable(
                          message: _load?.message ??
                              'This offer is unavailable right now.',
                          onRetry: _load?.status == PaywallStatus.unavailable
                              ? null
                              : () => _loadProducts(refresh: true),
                        )
                      else ...[
                        _PriceHeadline(
                          offer: offer!,
                          compareAt: _compareAt,
                          trialLabel: _trialLabel,
                        ),
                        const SizedBox(height: 20),
                        _OfferSummaryCard(offer: offer),
                      ],
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
              AppButton(
                label: _ctaLabel(offer),
                variant: AppButtonVariant.gradient,
                icon: Icons.bolt_rounded,
                loading: _busy,
                // Nothing to claim until Apphud returns a real product.
                onPressed: offer == null ? null : _claim,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy ? null : _goHome,
                child: Text(
                  'No thanks, maybe later',
                  style:
                      text.titleMedium?.copyWith(color: AppColors.textSecondary),
                ),
              ),
              const _OfferLegalFooter(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Soft full-bleed gradient backdrop (design-system stand-in for hero media).
class _OfferBackdrop extends StatelessWidget {
  const _OfferBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: AppColors.background),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.7),
            radius: 1.15,
            colors: [
              AppColors.accentBadge.withValues(alpha: 0.26),
              AppColors.background.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 1.0],
          ),
        ),
      ),
    );
  }
}

/// The live "offer ends in mm:ss" urgency banner.
class _CountdownBanner extends StatelessWidget {
  const _CountdownBanner({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.accentBadge.withValues(alpha: 0.14),
        borderRadius: AppRadii.rPill,
        border: Border.all(
          color: AppColors.accentBadge.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_rounded,
              color: AppColors.accentBadge, size: 20),
          const SizedBox(width: 10),
          Text(
            'Offer ends in',
            style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: text.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// The offered price, with the placement's dearest plan struck through beside it
/// so the contrast shown is a real, live comparison.
class _PriceHeadline extends StatelessWidget {
  const _PriceHeadline({required this.offer, this.compareAt, this.trialLabel});

  final SubscriptionProduct offer;

  /// The dearer plan to strike through, when the placement offers one.
  final SubscriptionProduct? compareAt;

  /// Intro-offer wording, already gated on real Apphud eligibility. Null means
  /// no trial is promised and only the price below is shown.
  final String? trialLabel;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final SubscriptionProduct? compare = compareAt;
    final String? perWeek = offer.pricePerWeek;
    final String cadence =
        offer.period == null ? '' : 'per ${offer.period!.unit}';

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (compare != null) ...[
              Text(
                compare.price,
                style: text.titleLarge?.copyWith(
                  color: AppColors.textSecondary,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Text(
              offer.price,
              style: text.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          perWeek != null ? '$cadence · just $perWeek/week' : cadence,
          style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        if (trialLabel != null) ...[
          const SizedBox(height: 6),
          Text(
            '$trialLabel, then ${offer.price}',
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

/// Placeholder while the Apphud placement loads.
class _OfferLoading extends StatelessWidget {
  const _OfferLoading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          const SizedBox(
            height: 26,
            width: 26,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          const SizedBox(height: 14),
          Text(
            'Loading your offer…',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Honest message when the placement returned nothing / the store is
/// unavailable / the load failed — never a blank offer wall.
class _OfferUnavailable extends StatelessWidget {
  const _OfferUnavailable({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Icon(Icons.info_outline_rounded,
              color: AppColors.textSecondary, size: 26),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 14),
            AppButton(
              label: 'Try again',
              variant: AppButtonVariant.outlined,
              expanded: false,
              height: 40,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}

/// A short summary card listing what the discounted year includes.
class _OfferSummaryCard extends StatelessWidget {
  const _OfferSummaryCard({required this.offer});

  final SubscriptionProduct offer;

  static const List<String> _includes = <String>[
    'Full sound library, all three slots',
    'New sounds added every month',
    'Best value — locked in for a year',
  ];

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                offer.title,
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (offer.subtitle != null)
                Flexible(
                  child: Text(
                    offer.subtitle!,
                    textAlign: TextAlign.right,
                    style: text.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          for (final String line in _includes) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    line,
                    style: text.bodyMedium?.copyWith(height: 1.3),
                  ),
                ),
              ],
            ),
            if (line != _includes.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

/// Auto-renewal disclosure plus Terms / Privacy links (kept legally accurate).
class _OfferLegalFooter extends StatelessWidget {
  const _OfferLegalFooter();

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final TextStyle base =
        text.bodySmall?.copyWith(color: AppColors.textSecondary) ??
            const TextStyle();

    return Column(
      children: [
        Text(
          'Renews automatically at the price shown above until cancelled. '
          'Manage or cancel anytime in your store account settings.',
          textAlign: TextAlign.center,
          style: base.copyWith(height: 1.3, fontSize: 11),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegalLink(
              label: 'Terms',
              url: kTermsOfUseUrl,
              style: base,
            ),
            Text('   •   ', style: base),
            _LegalLink(
              label: 'Privacy',
              url: kPrivacyPolicyUrl,
              style: base,
            ),
          ],
        ),
      ],
    );
  }
}

/// A tappable legal link styled as the app's link colour with an underline, so
/// it reads as clearly interactive. Opens [url] in the browser, guarded against
/// launch failure via [openLegalLink].
class _LegalLink extends StatelessWidget {
  const _LegalLink({
    required this.label,
    required this.url,
    required this.style,
  });

  final String label;
  final String url;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => openLegalLink(context, url),
      child: Text(
        label,
        style: style.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.primary,
        ),
      ),
    );
  }
}
