import 'package:flutter/material.dart';

import 'package:drivana/core/router/app_router.dart';
import 'package:drivana/ui/components/components.dart';

/// Onboarding — what the app does (app_spec id "0001").
///
/// Second onboarding step: states, plainly, the value the app actually
/// delivers — signature departure/arrival sounds, trips with a safe-driving
/// score, and the glanceable board. It quotes no ratings, counts or
/// testimonials, and it deliberately does NOT ask for a rating either — App
/// Store guideline 5.6.3 forbids soliciting one before the user has used the
/// app, so the review request lives only in Settings, where the user starts
/// it. Continuing (or skipping) advances the flow to "0002".
class Screen_0001 extends StatefulWidget {
  const Screen_0001({super.key});

  @override
  State<Screen_0001> createState() => _Screen_0001State();
}

class _Screen_0001State extends State<Screen_0001> {
  void _continue() {
    AppRouter.go(context, '0002');
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return AppScaffold(
      onboarding: true,
      topBar: AppTopBar(
        actions: [
          TextButton(
            onPressed: _continue,
            child: Text(
              'Skip',
              style: text.titleMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
      extendBodyBehindTopBar: false,
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
                      const SizedBox(height: 8),
                      Container(
                        height: 88,
                        width: 88,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.ratingStar.withValues(alpha: 0.16),
                          borderRadius: AppRadii.rLg,
                        ),
                        child: const Icon(
                          Icons.directions_car_filled_rounded,
                          color: AppColors.ratingStar,
                          size: 44,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Built around your drive',
                        textAlign: TextAlign.center,
                        style: text.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Set a departure and arrival sound for your car, see '
                        'every trip and a safe-driving score, and keep a calm, '
                        'glanceable board on the road.',
                        textAlign: TextAlign.center,
                        style: text.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              AppButton(
                label: 'Continue',
                variant: AppButtonVariant.gradient,
                icon: Icons.arrow_forward_rounded,
                onPressed: _continue,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
