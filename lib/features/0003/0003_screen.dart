import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:drivana/core/data/legal_links.dart';
import 'package:drivana/core/router/app_router.dart';
import 'package:drivana/core/state.dart';
import 'package:drivana/ui/components/components.dart';

/// The App Store product page for this app, reused for review + share links.
const String kAppStoreUrl = 'https://apps.apple.com/app/id6793113392';

/// Menu / Settings drawer (app_spec id "0003").
///
/// The side menu reached from the tab roots: a "Go Premium" promo for free
/// users, a link into the Membership detail screen, the setup guide, support
/// links and an about section. Composed only from the shared design system;
/// every string is paraphrased and icons use the app's own rounded Material set
/// per the anti-clone rules.
class Screen_0003 extends StatelessWidget {
  const Screen_0003({super.key});

  @override
  Widget build(BuildContext context) {
    // Reactively mirror the live PRO entitlement: free users see the Go Premium
    // promo + upgrade routes, subscribers see their membership summary instead.
    return ValueListenableBuilder<bool>(
      valueListenable: AppState.isPro,
      builder: (context, isPro, _) => _MenuView(isPremium: isPro),
    );
  }
}

class _MenuView extends StatelessWidget {
  const _MenuView({required this.isPremium});

  final bool isPremium;

  /// Open the system mail composer pre-addressed to support.
  Future<void> _contact(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    bool ok = false;
    try {
      ok = await launchUrl(
        Uri.parse(
          'mailto:vektor9966@gmail.com?subject=Drivana',
        ),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      ok = false;
    }
    if (!ok) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Could not open your mail app')),
        );
    }
  }

  /// Open the real system share sheet with the App Store link.
  Future<void> _share(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await Share.share(
        'Check out Drivana on the App Store: $kAppStoreUrl',
      );
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Could not open the share sheet')),
        );
    }
  }

  /// Open the App Store review page for this app.
  Future<void> _review(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    bool ok = false;
    try {
      ok = await launchUrl(
        Uri.parse('$kAppStoreUrl?action=write-review'),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      ok = false;
    }
    if (!ok) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Could not open the App Store')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(
        title: 'Menu',
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
          // Go Premium vs Membership hero. Free users see the upgrade promo;
          // subscribers see their active plan summary instead.
          if (isPremium)
            _MembershipSummaryCard(
              onManage: () => AppRouter.go(context, '0012'),
            )
          else
            _GoPremiumCard(
              onUpgrade: () => PurchaseFlow.openPaywall(context),
            ),
          const SizedBox(height: 20),

          // Account / plan.
          const AppSectionHeader(
            title: 'Your plan',
            padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
          ),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                AppListTile(
                  title: 'Membership',
                  subtitle: isPremium
                      ? 'Premium — manage or review'
                      : 'See plans and what you get',
                  leadingIcon: Icons.card_membership_rounded,
                  onTap: () => AppRouter.go(context, '0012'),
                ),
                const _Divider(),
                AppListTile(
                  title: 'Restore a purchase',
                  subtitle: 'Already subscribed? Bring it back',
                  leadingIcon: Icons.restore_rounded,
                  onTap: () => PurchaseFlow.restore(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Settings: reach Appearance/Theme (0009), Language (0008), Units
          // (0010) and Break Reminders. The Appearance row lets the user switch
          // Light/Dark/System, which recolors the whole app via the
          // theme-aware design tokens.
          const AppSectionHeader(
            title: 'Settings',
            padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
          ),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                AppListTile(
                  title: 'Appearance',
                  subtitle: 'System, Light or Dark theme',
                  leadingIcon: Icons.brightness_6_rounded,
                  onTap: () => AppRouter.go(context, '0009'),
                ),
                const _Divider(),
                AppListTile(
                  title: 'Language',
                  subtitle: 'Choose your display language',
                  leadingIcon: Icons.language_rounded,
                  onTap: () => AppRouter.go(context, '0008'),
                ),
                const _Divider(),
                AppListTile(
                  title: 'Units',
                  subtitle: 'Distance, pressure and temperature',
                  leadingIcon: Icons.straighten_rounded,
                  onTap: () => AppRouter.go(context, '0010'),
                ),
                const _Divider(),
                AppListTile(
                  title: 'Break Reminders',
                  subtitle: 'Nudges to stop and stretch on long drives',
                  leadingIcon: Icons.free_breakfast_rounded,
                  onTap: () => AppRouter.go(context, 'break_reminders'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Setup.
          const AppSectionHeader(
            title: 'Setup',
            padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
          ),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                AppListTile(
                  title: 'Setup Guide',
                  subtitle: 'Wire your departure and arrival cues to Shortcuts',
                  leadingIcon: Icons.auto_fix_high_rounded,
                  onTap: () => AppRouter.go(context, 'connection_guide'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Support.
          const AppSectionHeader(
            title: 'Support',
            padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
          ),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                AppListTile(
                  title: 'Get in touch',
                  subtitle: 'Questions or feedback? Reach the team',
                  leadingIcon: Icons.mark_email_read_rounded,
                  onTap: () => _contact(context),
                ),
                const _Divider(),
                AppListTile(
                  title: 'Leave a review',
                  subtitle: 'Tell others what you think',
                  leadingIcon: Icons.reviews_rounded,
                  onTap: () => _review(context),
                ),
                const _Divider(),
                AppListTile(
                  title: 'Tell a friend',
                  subtitle: 'Share the app',
                  leadingIcon: Icons.ios_share_rounded,
                  onTap: () => _share(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // About.
          const AppSectionHeader(
            title: 'About',
            padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
          ),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                AppListTile(
                  title: 'Privacy notice',
                  leadingIcon: Icons.shield_moon_rounded,
                  onTap: () => openLegalLink(context, kPrivacyPolicyUrl),
                ),
                const _Divider(),
                AppListTile(
                  title: 'Terms of service',
                  leadingIcon: Icons.description_rounded,
                  onTap: () => openLegalLink(context, kTermsOfUseUrl),
                ),
                const _Divider(),
                const AppListTile(
                  title: 'App version',
                  // The app describing itself — show its real icon.
                  leading: AppIconMark(size: 38),
                  trailingText: '1.0.0',
                  showChevron: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Made for people who love a good drive.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Free-tier promo card: gradient surface with a Go Premium call to action.
class _GoPremiumCard extends StatelessWidget {
  const _GoPremiumCard({required this.onUpgrade});

  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return AppCard(
      gradient: AppGradients.cta,
      padding: const EdgeInsets.all(18),
      onTap: onUpgrade,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 44,
                width: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.onPrimary.withValues(alpha: 0.18),
                  borderRadius: AppRadii.rSm,
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.onPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unlock Premium',
                      style: text.titleLarge?.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Every sound, no limits',
                      style: text.bodyMedium?.copyWith(
                        color: AppColors.onPrimary.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Go Premium',
            variant: AppButtonVariant.white,
            trailingIcon: Icons.arrow_forward_rounded,
            onPressed: onUpgrade,
          ),
        ],
      ),
    );
  }
}

/// Subscriber summary card shown in place of the promo for premium users.
class _MembershipSummaryCard extends StatelessWidget {
  const _MembershipSummaryCard({required this.onManage});

  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(18),
      onTap: onManage,
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppGradients.pro,
              borderRadius: AppRadii.rSm,
            ),
            child: Icon(
              Icons.verified_rounded,
              color: AppColors.background,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Premium',
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const AppBadge(
                      label: 'ACTIVE',
                      tone: AppBadgeTone.premium,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'You have full access',
                  style: text.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

/// Hairline divider between rows inside a grouped card.
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
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
