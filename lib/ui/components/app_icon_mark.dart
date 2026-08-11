import 'package:flutter/material.dart';

/// The app's real launcher icon, rendered as an in-app app mark.
///
/// Use this anywhere a graphic stands for "this app" (splash, onboarding hero,
/// paywall header, the About / app-version row). Functional glyphs — a play
/// button, a speaker, a tab-bar icon — are NOT app marks and keep their icon.
///
/// The bundled PNG is deliberately square (Apple masks it on the home screen),
/// so it is clipped here with the iOS superellipse-approximating corner radius
/// of ~22.5% of the side.
class AppIconMark extends StatelessWidget {
  const AppIconMark({super.key, required this.size, this.boxShadow});

  /// Side length of the (square) mark, in logical pixels.
  final double size;

  /// Optional glow/drop shadow, matching whatever the mark replaced.
  final List<BoxShadow>? boxShadow;

  static const String assetPath = 'assets/icon/app_icon.png';

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(size * 0.225);

    Widget mark = ClipRRect(
      borderRadius: radius,
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        // The source is 1024px; scale it down cleanly.
        filterQuality: FilterQuality.medium,
      ),
    );

    if (boxShadow != null && boxShadow!.isNotEmpty) {
      mark = DecoratedBox(
        decoration: BoxDecoration(borderRadius: radius, boxShadow: boxShadow),
        child: mark,
      );
    }

    return SizedBox(width: size, height: size, child: mark);
  }
}
