import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The base surface card every grouped block sits on. Honors the token
/// `surface` color, `radius_md` corner and the `elevation_style: soft` shadow.
///
/// Optionally renders a gradient border/fill for highlighted (selected) cards
/// using the primary token — used by paywall package cards and selected slots.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppDimens.gutter),
    this.radius,
    this.selected = false,
    this.color,
    this.gradient,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double? radius;
  final bool selected;
  final Color? color;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final BorderRadius r = BorderRadius.circular(radius ?? AppRadii.md);

    final BoxDecoration decoration = BoxDecoration(
      color: gradient == null ? (color ?? AppColors.surface) : null,
      gradient: gradient,
      borderRadius: r,
      border: selected
          ? Border.all(color: AppColors.primary, width: 1.5)
          : null,
      boxShadow: AppStyleTokens.elevationStyle == 'flat'
          ? null
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
    );

    final Widget content = Padding(padding: padding, child: child);

    if (onTap == null) {
      return DecoratedBox(decoration: decoration, child: content);
    }

    return DecoratedBox(
      decoration: decoration,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: r,
          onTap: onTap,
          child: content,
        ),
      ),
    );
  }
}
