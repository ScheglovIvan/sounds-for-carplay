import 'package:flutter/material.dart';

import 'package:drivana/core/router/app_router.dart';
import 'package:drivana/ui/components/components.dart';

/// Onboarding — welcome intro (app_spec id "0000").
///
/// First step of the onboarding flow: introduces Drivana's core idea (a calmer,
/// more focused drive) and hands off to the social-proof step ("0001").
/// Composed only from the shared design system; all copy is paraphrased and
/// icons use the app's own consistent (rounded) Material set, per the
/// anti-clone rules.
class Screen_0000 extends StatelessWidget {
  const Screen_0000({super.key});

  static const List<_Highlight> _highlights = <_Highlight>[
    _Highlight(
      icon: Icons.self_improvement_rounded,
      title: 'Signature drive sounds',
      body: 'Pick a departure and arrival sound for your car, plus gentle cues.',
    ),
    _Highlight(
      icon: Icons.route_rounded,
      title: 'Every trip, remembered',
      body: 'Live stats on the road and a history of where you have been.',
    ),
    _Highlight(
      icon: Icons.shield_moon_rounded,
      title: 'Your driving score',
      body: 'See how smooth each drive was and improve it over time.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return AppScaffold(
      onboarding: true,
      body: SafeArea(
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
                      const SizedBox(height: 32),
                      // Neutral calm-driving hero: a clean design-system
                      // gradient panel, no product/platform imagery.
                      const _WelcomeHero(),
                      const SizedBox(height: 28),
                      Text(
                        'Welcome to Drivana',
                        textAlign: TextAlign.center,
                        style: text.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Drive calmer: drive sounds, gentle cues, live trip '
                        'stats and your own safe-driving score.',
                        textAlign: TextAlign.center,
                        style: text.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 32),
                      for (final _Highlight h in _highlights) ...[
                        _HighlightRow(highlight: h),
                        const SizedBox(height: 12),
                      ],
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              AppButton(
                label: 'Get started',
                variant: AppButtonVariant.white,
                trailingIcon: Icons.arrow_forward_rounded,
                onPressed: () => AppRouter.go(context, '0001'),
              ),
              const SizedBox(height: 12),
              Text(
                'Free to try • No account needed',
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// The welcome hero: a clean, neutral gradient panel with a calm-driving glyph.
///
/// Deliberately NOT a product screenshot — the design system's own gradient and
/// a rounded Material glyph keep the first screen free of any device or
/// platform imagery.
class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 168,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppGradients.cta,
        borderRadius: AppRadii.rLg,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGradientEnd.withValues(alpha: 0.32),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 18,
            left: 0,
            right: 0,
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 48),
              decoration: BoxDecoration(
                color: AppColors.onPrimary.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Icon(
            Icons.explore_rounded,
            color: AppColors.onPrimary,
            size: 72,
          ),
        ],
      ),
    );
  }
}

class _Highlight {
  const _Highlight({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

class _HighlightRow extends StatelessWidget {
  const _HighlightRow({required this.highlight});

  final _Highlight highlight;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.16),
              borderRadius: AppRadii.rSm,
            ),
            child: Icon(highlight.icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  highlight.title,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  highlight.body,
                  style: text.bodyMedium?.copyWith(
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
