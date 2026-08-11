import 'package:flutter/material.dart';

import 'package:drivana/core/data/legal_links.dart';
import 'package:drivana/core/models/subscription.dart';
import 'package:drivana/core/services/apphud_service.dart';
import 'package:drivana/core/services/entitlement_service.dart';
import 'package:drivana/core/state.dart';
import 'package:drivana/ui/components/components.dart';

/// Standard subscription paywall — "Unlock everything" (app_spec id "0002").
///
/// Third onboarding step / the GET PRO placement. The plans are loaded LIVE from
/// the Apphud placement (`main_drivana`) — titles, prices and product
/// ids all come from Apphud at runtime, so a product added later in the Apphud
/// dashboard appears here without an app update. Nothing about the catalog is
/// hardcoded. A benefit list and a single primary CTA run the real purchase.
///
/// Every load state is handled explicitly (loading / ready / no products /
/// store unavailable / error) so the paywall is never blank.
///
/// Layout (block order/sizing) follows `source/0002.json`; all color, type and
/// rounding come from the frozen design system. Copy is paraphrased and icons
/// use the app's own rounded Material set per the anti-clone rules. Dismissing
/// the paywall routes to the discounted recovery offer (`paywall_special`); a
/// successful purchase/restore proceeds into the app.
class Screen_0002 extends StatefulWidget {
  const Screen_0002({super.key});

  @override
  State<Screen_0002> createState() => _Screen_0002State();
}

class _Screen_0002State extends State<Screen_0002> with WidgetsBindingObserver {
  /// Everything a PRO subscription unlocks (paraphrased benefits).
  static const List<_Perk> _perks = <_Perk>[
    _Perk(
      icon: Icons.library_music_rounded,
      text: 'The complete sound library — hundreds of cues',
    ),
    _Perk(
      icon: Icons.dashboard_customize_rounded,
      text: 'Fill all three drive-moment slots at once',
    ),
    _Perk(
      icon: Icons.auto_awesome_rounded,
      text: 'Fresh sounds dropped every month',
    ),
    _Perk(
      icon: Icons.play_circle_fill_rounded,
      text: 'Unlimited previews and instant setup',
    ),
  ];

  bool _busy = false;
  bool _loading = true;

  /// The placement's products, straight from Apphud.
  PaywallLoad? _load;

  /// Currently selected product id (defaults to the yearly plan Apphud
  /// returned — resolved from the real billing periods, never a hardcoded id).
  String? _selectedId;

  /// Product ids whose intro offer / free trial this user is ACTUALLY eligible
  /// for, per `Apphud.checkEligibilityForIntroductoryOffer()`. Trial wording is
  /// shown only for ids in here — a user Apple would charge immediately sees the
  /// plain price instead.
  Set<String> _trialEligible = const <String>{};

  /// Guards `Apphud.paywallShown()` to one call per presentation of this screen
  /// (not per rebuild, and not again on Retry).
  bool _impressionReported = false;

  List<SubscriptionProduct> get _products =>
      _load?.products ?? const <SubscriptionProduct>[];

  SubscriptionProduct? get _selected {
    for (final SubscriptionProduct p in _products) {
      if (p.vendorProductId == _selectedId) return p;
    }
    return _products.isEmpty ? null : _products.first;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Fetched fresh right before the paywall is shown — never the prices this
    // build happened to read at SDK start.
    _loadProducts();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// A storefront can change while the app is backgrounded, so re-read the
  /// products before the user can act on them again.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_busy) {
      _loadProducts(refresh: true);
    }
  }

  Future<void> _loadProducts({bool refresh = false}) async {
    // Only show the spinner when there is nothing on screen yet; a background
    // refresh must not flash over prices that are already correct.
    if (refresh && _products.isEmpty && !_loading) {
      setState(() => _loading = true);
    }
    final PaywallLoad load = await ApphudService.loadPaywall(refresh: refresh);
    if (!mounted) return;
    final String? previous = _selectedId;
    final bool keepSelection = previous != null &&
        load.products.any((p) => p.vendorProductId == previous);
    setState(() {
      _load = load;
      _loading = false;
      // Pre-select the YEARLY plan — the one the savings badge sits on — so the
      // highlighted saving and the plan in the CTA always agree. A plan the
      // user already picked is kept across a refresh.
      _selectedId = keepSelection ? previous : _preselectId(load.products);
    });

    // Record the impression as soon as the paywall has real content to show.
    // Once per presentation — Apphud's conversion rates and A/B tests are built
    // on this call, and a repeat would skew them.
    if (!_impressionReported && load.paywall != null) {
      _impressionReported = true;
      await ApphudService.paywallShown(load.paywall);
    }

    await _resolveTrialEligibility(load.products);
  }

  /// Ask Apphud which products' intro offers this user would really get, so the
  /// paywall never promises a trial Apple would not honour.
  Future<void> _resolveTrialEligibility(
      List<SubscriptionProduct> products) async {
    final Set<String> eligible = <String>{};
    for (final SubscriptionProduct p in products) {
      if (await ApphudService.introEligibility(p)) {
        eligible.add(p.vendorProductId);
      }
    }
    if (!mounted) return;
    setState(() => _trialEligible = eligible);
  }

  /// The trial/intro wording to show for [product], or null when it has no
  /// offer or this user isn't eligible for it.
  String? _trialLabel(SubscriptionProduct? product) {
    if (product == null) return null;
    if (!_trialEligible.contains(product.vendorProductId)) return null;
    return product.introOfferLabel;
  }

  /// The plan to pre-select: the YEARLY one, resolved from the live products'
  /// real billing periods (the longest period Apphud returned). That is the
  /// plan the "% OFF" badge lands on, so the selection and the badge can't
  /// contradict each other. Ties — and placements with no periods at all — fall
  /// back to the lowest per-week cost, then to the first product.
  static String? _preselectId(List<SubscriptionProduct> products) {
    if (products.isEmpty) return null;
    SubscriptionProduct best = products.first;
    for (final SubscriptionProduct p in products) {
      final double weeks = p.period?.weeks ?? 0;
      final double bestWeeks = best.period?.weeks ?? 0;
      if (weeks > bestWeeks) {
        best = p;
      } else if (weeks == bestWeeks) {
        final double? cost = p.weeklyCost;
        final double? bestCost = best.weeklyCost;
        if (cost != null && bestCost != null && cost < bestCost) best = p;
      }
    }
    return best.vendorProductId;
  }

  Future<void> _purchase() async {
    final SubscriptionProduct? product = _selected;
    if (_busy || product == null) return;
    setState(() => _busy = true);
    final EntitlementResult result =
        await EntitlementService.instance.purchase(product);
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

  /// Enter the app, clearing the onboarding/paywall stack. Reaching the home
  /// this way completes first-run onboarding so later launches skip it.
  void _goHome() {
    AppState.completeOnboarding();
    // The Drive tab (Focus Drive home) is the app's landing screen.
    Navigator.of(context).pushNamedAndRemoveUntil('/0007', (route) => false);
  }

  /// Dismissing the standard paywall surfaces the discounted recovery offer.
  void _dismiss() {
    Navigator.of(context).pushReplacementNamed('/paywall_special');
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    // Clear the (full-bleed) top bar that the body extends behind.
    final double topPad = MediaQuery.of(context).padding.top + 56 + 8;

    return AppScaffold(
      extendBodyBehindTopBar: true,
      background: const _PaywallBackdrop(),
      topBar: AppTopBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 26),
          color: AppColors.textPrimary,
          onPressed: _busy ? null : _dismiss,
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
                      // Paywall hero mark — the app's real launcher icon.
                      AppIconMark(
                        size: 84,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryGradientEnd
                                .withValues(alpha: 0.35),
                            blurRadius: 26,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Unlock the full experience',
                        textAlign: TextAlign.center,
                        style: text.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Every sound, every slot, no limits — go Premium and '
                        'make each drive your own.',
                        textAlign: TextAlign.center,
                        style: text.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 22),
                      for (final _Perk perk in _perks) ...[
                        _PerkRow(perk: perk),
                        const SizedBox(height: 12),
                      ],
                      const SizedBox(height: 8),
                      if (_loading)
                        const _PlansLoading()
                      else if (_products.isEmpty)
                        _PlansUnavailable(
                          message: _load?.message ??
                              'No subscription plans are available right now.',
                          onRetry: _load?.status == PaywallStatus.unavailable
                              ? null
                              : () => _loadProducts(refresh: true),
                        )
                      else
                        for (final SubscriptionProduct product in _products) ...[
                          _PlanCard(
                            product: product,
                            trialLabel: _trialLabel(product),
                            selected: product.vendorProductId == _selectedId,
                            onTap: () => setState(
                                () => _selectedId = product.vendorProductId),
                          ),
                          const SizedBox(height: 12),
                        ],
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
              AppButton(
                label: _ctaLabel(),
                variant: AppButtonVariant.gradient,
                loading: _busy,
                // Without a live product there is nothing to buy — the CTA is
                // disabled rather than pretending a purchase can happen.
                onPressed: _selected == null ? null : _purchase,
              ),
              const SizedBox(height: 10),
              const _LegalFooter(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// CTA copy built from the selected Apphud product's own price and period.
  ///
  /// The trial variant appears ONLY when Apphud confirmed this user is eligible
  /// for that product's introductory offer.
  String _ctaLabel() {
    if (_loading) return 'Loading plans…';
    final SubscriptionProduct? p = _selected;
    if (p == null) return 'Plans unavailable';
    final String? trial = _trialLabel(p);
    if (trial != null) return 'Start your $trial';
    if (!p.hasStorePrice) return 'Continue';
    final BillingPeriod? period = p.period;
    return period == null
        ? 'Continue — ${p.price}'
        : 'Continue — ${p.price}/${period.unit}';
  }
}

/// Placeholder shown while the Apphud placement is loading, so the paywall
/// always has visible content in the plan slot.
class _PlansLoading extends StatelessWidget {
  const _PlansLoading();

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
            'Loading plans…',
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

/// Honest message shown when the placement returned no products, the store is
/// unavailable on this platform, or the load failed — never a blank paywall.
class _PlansUnavailable extends StatelessWidget {
  const _PlansUnavailable({required this.message, this.onRetry});

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

/// A soft, full-bleed gradient backdrop that stands in for the paywall hero
/// media (design system owns the look, so no source artwork is bundled).
class _PaywallBackdrop extends StatelessWidget {
  const _PaywallBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: AppColors.background),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.75),
            radius: 1.1,
            colors: [
              AppColors.primaryGradientStart.withValues(alpha: 0.32),
              AppColors.background.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 1.0],
          ),
        ),
      ),
    );
  }
}

class _Perk {
  const _Perk({required this.icon, required this.text});

  final IconData icon;
  final String text;
}

class _PerkRow extends StatelessWidget {
  const _PerkRow({required this.perk});

  final _Perk perk;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          height: 34,
          width: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.16),
            borderRadius: AppRadii.rSm,
          ),
          child: Icon(perk.icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            perk.text,
            style: text.bodyMedium?.copyWith(height: 1.3),
          ),
        ),
        const Icon(Icons.check_rounded, color: AppColors.success, size: 20),
      ],
    );
  }
}

/// A selectable subscription plan row inside the paywall.
class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.product,
    required this.selected,
    required this.onTap,
    this.trialLabel,
  });

  /// A live Apphud product — every value rendered below comes from it.
  final SubscriptionProduct product;

  /// Intro-offer wording, already gated on real Apphud eligibility. Null means
  /// this user gets no trial, so only the plain price is shown.
  final String? trialLabel;

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return AppCard(
      selected: selected,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          _RadioDot(selected: selected),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        product.title,
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (product.discountBadge != null) ...[
                      const SizedBox(width: 8),
                      AppBadge(label: product.discountBadge!),
                    ],
                  ],
                ),
                if (product.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    product.subtitle!,
                    style: text.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
                if (trialLabel != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '$trialLabel, then ${product.price}',
                    style: text.bodySmall?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                product.price,
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (product.pricePerWeek != null)
                Text(
                  '${product.pricePerWeek}/wk',
                  style:
                      text.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      width: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.textSecondary,
          width: 2,
        ),
        color: selected ? AppColors.primary : Colors.transparent,
      ),
      child: selected
          ? const Icon(Icons.check_rounded,
              color: AppColors.onPrimary, size: 15)
          : null,
    );
  }
}

/// Auto-renewal disclosure plus Terms / Privacy links (kept legally accurate).
class _LegalFooter extends StatelessWidget {
  const _LegalFooter();

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final TextStyle base =
        text.bodySmall?.copyWith(color: AppColors.textSecondary) ??
            const TextStyle();

    return Column(
      children: [
        Text(
          'Auto-renews until cancelled. Manage or cancel anytime in your '
          'store account settings.',
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
