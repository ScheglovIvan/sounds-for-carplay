import 'package:flutter/material.dart';

import 'package:drivana/core/data/legal_links.dart';
import 'package:drivana/core/services/apphud_service.dart';
import 'package:drivana/core/state.dart';
import 'package:drivana/ui/components/components.dart';

/// Membership detail (app_spec id "0012").
///
/// Shows the current plan status, what Premium unlocks and the manage/restore
/// actions. Reactively reflects the live PRO entitlement: subscribers see their
/// active plan and auto-renewal date; free users see the upgrade path. Composed
/// only from the shared design system; all copy is paraphrased per anti-clone.
class Screen_0012 extends StatelessWidget {
  const Screen_0012({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Entitlement>(
      valueListenable: AppState.entitlement,
      builder: (context, entitlement, _) =>
          _MembershipView(entitlement: entitlement),
    );
  }
}

class _Perk {
  const _Perk({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;
}

class _MembershipView extends StatelessWidget {
  const _MembershipView({required this.entitlement});

  final Entitlement entitlement;

  bool get isPremium => entitlement.isActive;

  static const List<_Perk> _perks = <_Perk>[
    _Perk(
      icon: Icons.library_music_rounded,
      title: 'The whole library',
      body: 'Play and assign every sound across all categories.',
    ),
    _Perk(
      icon: Icons.all_inclusive_rounded,
      title: 'No caps',
      body: 'Set as many connect, leave and arrival cues as you like.',
    ),
    _Perk(
      icon: Icons.block_flipped,
      title: 'Zero interruptions',
      body: 'A clean, distraction-free experience throughout.',
    ),
    _Perk(
      icon: Icons.bolt_rounded,
      title: 'First in line',
      body: 'Fresh sounds and features land on your device first.',
    ),
  ];

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return AppScaffold(
      topBar: AppTopBar(
        title: 'Membership',
        showBack: true,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppDimens.gutter,
          8,
          AppDimens.gutter,
          28,
        ),
        children: [
          _StatusHero(isPremium: isPremium),
          const SizedBox(height: 22),

          // Active-subscription summary: plan + auto-renewal date, pulled from
          // the resolved entitlement (Adapty stand-in).
          if (isPremium) ...[
            const AppSectionHeader(
              title: 'Your subscription',
              padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
            ),
            _SubscriptionCard(entitlement: entitlement),
            const SizedBox(height: 22),
          ],

          AppSectionHeader(
            title: isPremium ? 'Included with Premium' : 'What Premium unlocks',
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          ),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                for (int i = 0; i < _perks.length; i++) ...[
                  _PerkRow(perk: _perks[i]),
                  if (i != _perks.length - 1)
                    Padding(
                      padding:
                          const EdgeInsets.only(left: AppDimens.gutter + 52),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color:
                            AppColors.textSecondary.withValues(alpha: 0.14),
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Manage.
          const AppSectionHeader(
            title: 'Manage',
            padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
          ),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                AppListTile(
                  title: 'Restore a purchase',
                  subtitle: 'Recover a subscription tied to your account',
                  leadingIcon: Icons.restore_rounded,
                  onTap: () => PurchaseFlow.restore(context),
                ),
                _rowDivider(),
                AppListTile(
                  title: 'Manage subscription',
                  subtitle: 'Change or cancel in the App Store',
                  leadingIcon: Icons.settings_suggest_rounded,
                  onTap: () => _toast(
                    context,
                    'Opening your App Store subscriptions…',
                  ),
                ),
                _rowDivider(),
                AppListTile(
                  title: 'Billing terms',
                  leadingIcon: Icons.receipt_long_rounded,
                  onTap: () => openLegalLink(context, kTermsOfUseUrl),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          const AppBanner(
            tone: AppBannerTone.info,
            icon: Icons.autorenew_rounded,
            title: 'Auto-renewing',
            message:
                'Plans renew automatically until cancelled. Turn off renewal '
                'anytime in your App Store account settings.',
          ),
          const SizedBox(height: 20),

          if (!isPremium)
            AppButton(
              label: 'See Premium plans',
              trailingIcon: Icons.arrow_forward_rounded,
              onPressed: () => PurchaseFlow.openPaywall(context),
            ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              isPremium
                  ? 'Thanks for supporting the app.'
                  : 'Cancel anytime — no strings attached.',
              style: text.bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _rowDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: AppDimens.gutter + 52),
      child: Divider(
        height: 1,
        thickness: 1,
        color: AppColors.textSecondary.withValues(alpha: 0.14),
      ),
    );
  }
}

/// The top status card: crown mark, plan name, state badge and an upgrade CTA
/// for free users.
class _StatusHero extends StatelessWidget {
  const _StatusHero({required this.isPremium});

  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 72,
            width: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: isPremium ? AppGradients.pro : AppGradients.cta,
              borderRadius: AppRadii.rLg,
              boxShadow: [
                BoxShadow(
                  color: (isPremium
                          ? AppColors.proGradientEnd
                          : AppColors.primaryGradientEnd)
                      .withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              isPremium
                  ? Icons.workspace_premium_rounded
                  : Icons.lock_open_rounded,
              color:
                  isPremium ? AppColors.background : AppColors.onPrimary,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          AppBadge(
            label: isPremium ? 'PREMIUM' : 'FREE PLAN',
            tone: isPremium ? AppBadgeTone.premium : AppBadgeTone.neutral,
          ),
          const SizedBox(height: 12),
          Text(
            isPremium ? "You're all set" : 'Currently on the free plan',
            textAlign: TextAlign.center,
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            isPremium
                ? 'Every sound and feature is unlocked on this device.'
                : 'Upgrade to open the full library and lift every limit.',
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          if (!isPremium) ...[
            const SizedBox(height: 18),
            AppButton(
              label: 'Upgrade now',
              icon: Icons.workspace_premium_rounded,
              onPressed: () => PurchaseFlow.openPaywall(context),
            ),
          ],
        ],
      ),
    );
  }
}

/// Active-plan card: shows the subscribed product's name, its status and the
/// auto-renewal date resolved from the entitlement.
class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({required this.entitlement});

  final Entitlement entitlement;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    // Name the active plan from the live Apphud product when the placement has
    // already been loaded; otherwise fall back to the generic tier name.
    final SubscriptionProduct? product =
        ApphudService.cachedProductById(entitlement.productId ?? '');
    final String planName = product?.title ?? 'Premium';
    final DateTime? renews = entitlement.renewsAt;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium_rounded,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$planName plan',
                  style:
                      text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const AppBadge(label: 'ACTIVE', tone: AppBadgeTone.premium),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            renews != null
                ? 'Your subscription renews automatically on '
                    '${_formatDate(renews)}.'
                : 'Your subscription renews automatically until cancelled.',
            style: text.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime d) {
  const List<String> months = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[(d.month - 1) % 12]} ${d.day}, ${d.year}';
}

class _PerkRow extends StatelessWidget {
  const _PerkRow({required this.perk});

  final _Perk perk;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.gutter,
        vertical: 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 38,
            width: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Icon(perk.icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  perk.title,
                  style:
                      text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  perk.body,
                  style: text.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
