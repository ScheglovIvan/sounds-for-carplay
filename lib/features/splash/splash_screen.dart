import 'dart:async';

import 'package:flutter/material.dart';

import 'package:drivana/core/bootstrap/app_bootstrap.dart';
import 'package:drivana/core/router/app_router.dart';
import 'package:drivana/core/state.dart';
import 'package:drivana/ui/components/components.dart';

/// Branded launch / loading screen (app_spec id "splash").
///
/// First screen of the first-run onboarding flow. While it is shown the app
/// finishes booting its (stand-in) SDKs via [AppBootstrap], then routes forward:
///   * first run           -> the Welcome intro ("0000"), which chains into the
///                            social-proof step ("0001") and the paywall
///                            ("0002") before the Drive tab;
///   * a returning user    -> straight to the Drive tab / Focus Drive ("0007").
///
/// The look is built entirely from the frozen design system (onboarding
/// background, token type) around the app's OWN launcher icon. Per the
/// anti-clone rules it renders the app's OWN mark and a paraphrased wordmark —
/// it does NOT bundle the source app's splash raster, logo or wordmark.
class Screen_splash extends StatefulWidget {
  const Screen_splash({super.key});

  @override
  State<Screen_splash> createState() => _Screen_splashState();
}

class _Screen_splashState extends State<Screen_splash> {
  /// Keep the brand on screen for at least this long so the launch reads as a
  /// deliberate splash rather than a flash, even when init resolves instantly.
  static const Duration _minVisible = Duration(milliseconds: 1400);

  bool _routed = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    // Run initialization and the minimum-display timer together, then advance
    // once both complete.
    await Future.wait<void>(<Future<void>>[
      AppBootstrap.initialize(),
      Future<void>.delayed(_minVisible),
    ]);
    _advance();
  }

  void _advance() {
    if (_routed || !mounted) return;
    _routed = true;
    // Returning users skip onboarding; first-run users start the intro flow.
    final String next = AppState.onboardingComplete.value ? '/0007' : '/0000';
    Navigator.of(context).pushReplacementNamed(next);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return AppScaffold(
      onboarding: true,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(flex: 5),
            // App mark — the app's real launcher icon, iOS-masked.
            AppIconMark(
              size: 108,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGradientEnd.withValues(alpha: 0.40),
                  blurRadius: 34,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Drivana',
              textAlign: TextAlign.center,
              style: text.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Drive calmer — sounds, cues, trips and your safe-driving score.',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const Spacer(flex: 5),
            const _LoadingDots(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

/// A soft three-dot loading pulse in the primary accent (design-system stand-in
/// for the source app's Rive loader; no source animation asset is bundled).
class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List<Widget>.generate(3, (i) {
            // Stagger each dot's opacity across the loop for a wave pulse.
            final double phase = (_controller.value - i * 0.18) % 1.0;
            final double t = phase < 0 ? phase + 1.0 : phase;
            final double opacity = 0.3 + 0.7 * (1 - (t * 2 - 1).abs());
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Container(
                height: 9,
                width: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: opacity),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
