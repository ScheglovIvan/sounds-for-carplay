import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:drivana/ui/components/components.dart';
import 'package:drivana/core/router/app_router.dart';

/// Setup Guide (app_spec id "connection_guide").
///
/// An illustrated, swipeable step carousel that walks the user through wiring
/// their departure / arrival cues to an iOS Shortcuts automation, ending in a
/// hand-off to the Shortcuts app. Composed entirely from the shared
/// design-system components + tokens — no bespoke colors/fonts here.
class Screen_connection_guide extends StatefulWidget {
  const Screen_connection_guide({super.key});

  @override
  State<Screen_connection_guide> createState() =>
      _ScreenConnectionGuideState();
}

/// A single tutorial step.
class _GuideStep {
  const _GuideStep({
    required this.title,
    required this.body,
    this.image,
    this.glyph,
  });

  /// Bundled screenshot of the iOS Shortcuts step, when one illustrates it.
  final String? image;

  /// Fallback glyph for a step with no bundled illustration.
  final IconData? glyph;

  final String title;
  final String body;
}

class _ScreenConnectionGuideState extends State<Screen_connection_guide> {
  final PageController _controller = PageController();
  int _index = 0;

  // Paraphrased instructions (meaning preserved, wording intentionally new).
  static const List<_GuideStep> _steps = <_GuideStep>[
    _GuideStep(
      image: 'assets/media/guide_step_1.png',
      title: 'Open the Shortcuts app',
      body:
          'Swipe down on your Home Screen, search for “Shortcuts”, and tap to '
          'launch Apple’s built-in automation app.',
    ),
    _GuideStep(
      image: 'assets/media/guide_step_2.png',
      title: 'Create a new automation',
      body:
          'Switch to the Automation tab and tap “New Automation” to start '
          'building the trigger for your cue.',
    ),
    // No screenshot for this step: the bundled capture of the trigger list is
    // branded with the old concept, so a clean glyph stands in for it.
    _GuideStep(
      glyph: Icons.directions_car_filled_rounded,
      title: 'Pick the car-connection trigger',
      body:
          'Scroll the trigger list to the one for connecting to your car and '
          'choose it, so the cue fires the instant your car links up.',
    ),
    _GuideStep(
      image: 'assets/media/guide_step_4.png',
      title: 'Run it right away',
      body:
          'Keep “Is Connected” selected, choose “Run Immediately”, then continue '
          'to add the action.',
    ),
    _GuideStep(
      image: 'assets/media/guide_step_5.png',
      title: 'Play your chosen cue',
      body:
          'Add a “Play Sound” action and point it at your Departure, Arrival '
          'or Home cue. That’s it — you’re set!',
    ),
  ];

  bool get _isLast => _index == _steps.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLast) return;
    _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  void _back() {
    if (_index == 0) return;
    _controller.previousPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  /// Really open Apple's Shortcuts app through its public `shortcuts://` URL
  /// scheme, so the user lands where the automation is actually built. If the
  /// app is unavailable (Shortcuts removed, or a non-iOS preview) we say so
  /// instead of pretending the hand-off happened.
  Future<void> _openShortcuts() async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    bool ok = false;
    try {
      ok = await launchUrl(
        Uri.parse('shortcuts://'),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      ok = false;
    }
    if (!ok) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Could not open the Shortcuts app'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }
    if (mounted) _finish();
  }

  void _finish() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      AppRouter.go(context, '0006');
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return AppScaffold(
      topBar: AppTopBar(
        title: 'Setup Guide',
        showBack: true,
        onBack: _finish,
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _steps.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => _StepPage(
                step: _steps[i],
                number: i + 1,
                total: _steps.length,
              ),
            ),
          ),
          _Dots(count: _steps.length, index: _index),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.gutter,
              AppDimens.gutter,
              AppDimens.gutter,
              AppDimens.gutter,
            ),
            child: _isLast
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppButton(
                        label: 'Open Shortcuts',
                        icon: Icons.ios_share_rounded,
                        onPressed: _openShortcuts,
                      ),
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: _finish,
                        child: Text(
                          'I’ve finished setup',
                          style: text.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      if (_index > 0) ...[
                        Expanded(
                          child: AppButton(
                            label: 'Back',
                            variant: AppButtonVariant.outlined,
                            onPressed: _back,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: AppButton(
                          label: 'Next',
                          trailingIcon: Icons.arrow_forward_rounded,
                          onPressed: _next,
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

/// One full page of the carousel: numbered heading, illustration card, copy.
class _StepPage extends StatelessWidget {
  const _StepPage({
    required this.step,
    required this.number,
    required this.total,
  });

  final _GuideStep step;
  final int number;
  final int total;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.gutter,
        AppDimens.gutter,
        AppDimens.gutter,
        AppDimens.gutter,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step $number of $total',
            style: text.labelLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            step.title,
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            step.body,
            style: text.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          if (step.image != null)
            AppCard(
              color: AppColors.onPrimary,
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.sm),
                child: AspectRatio(
                  aspectRatio: 16 / 11,
                  child: Container(
                    color: AppColors.onPrimary,
                    alignment: Alignment.center,
                    child: Image.asset(
                      step.image!,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            )
          else
            AppCard(
              gradient: AppGradients.cta,
              padding: const EdgeInsets.all(12),
              child: AspectRatio(
                aspectRatio: 16 / 11,
                child: Center(
                  child: Icon(
                    step.glyph ?? Icons.auto_fix_high_rounded,
                    color: AppColors.onPrimary,
                    size: 72,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Slim page indicator whose active dot uses the primary token.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(count, (i) {
        final bool active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary
                : AppColors.textSecondary.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
