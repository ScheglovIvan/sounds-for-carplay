import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_top_bar.dart';

/// The standard page shell. Wraps [Scaffold] with the token background, an
/// optional [AppTopBar] and bottom bar, and an optional full-bleed [background]
/// layer (for splash / paywall hero media) drawn behind the body.
///
/// Set [onboarding] to paint the darker `background_onboarding` color.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.topBar,
    required this.body,
    this.bottomBar,
    this.background,
    this.floatingActionButton,
    this.safeTop = true,
    this.safeBottom = true,
    this.onboarding = false,
    this.backgroundColor,
    this.extendBodyBehindTopBar = false,
  });

  final AppTopBar? topBar;
  final Widget body;
  final Widget? bottomBar;

  /// Optional full-bleed layer painted behind the body (image/video/gradient).
  final Widget? background;
  final Widget? floatingActionButton;
  final bool safeTop;
  final bool safeBottom;
  final bool onboarding;
  final Color? backgroundColor;
  final bool extendBodyBehindTopBar;

  @override
  Widget build(BuildContext context) {
    final Color bg = backgroundColor ??
        (onboarding ? AppColors.backgroundOnboarding : AppColors.background);

    final Widget content = SafeArea(
      top: safeTop && topBar == null,
      bottom: safeBottom && bottomBar == null,
      child: body,
    );

    final Widget column = Column(
      children: [
        if (topBar != null && !extendBodyBehindTopBar) topBar!,
        Expanded(child: content),
      ],
    );

    return Scaffold(
      backgroundColor: bg,
      extendBodyBehindAppBar: extendBodyBehindTopBar,
      floatingActionButton: floatingActionButton,
      body: Stack(
        children: [
          if (background != null) Positioned.fill(child: background!),
          if (extendBodyBehindTopBar && topBar != null)
            Column(
              children: [
                Expanded(child: content),
              ],
            )
          else
            column,
          if (extendBodyBehindTopBar && topBar != null)
            Positioned(top: 0, left: 0, right: 0, child: topBar!),
        ],
      ),
      bottomNavigationBar: bottomBar,
    );
  }
}
