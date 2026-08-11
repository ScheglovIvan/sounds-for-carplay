import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The visual variants a primary action button can take. All are driven by the
/// divergent `design_tokens` — no hardcoded colors here.
enum AppButtonVariant {
  /// Full-bleed gradient pill (the primary action-button gradient).
  gradient,

  /// White pill CTA — `cta_light` (Get Started, Continue, paywall Continue).
  white,

  /// Outlined pill honoring `design_tokens.button_style: outlined`.
  outlined,

  /// Flat translucent/surface pill for secondary actions.
  ghost,
}

/// The single primary/secondary button used across every screen.
///
/// Composes ONLY theme + token values. Pass a [variant] to switch between the
/// gradient CTA, white pill, outlined and ghost looks. Height comes from
/// `design_tokens.dimension.button_height` and the corner from `radius_pill`.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.gradient,
    this.icon,
    this.trailingIcon,
    this.expanded = true,
    this.loading = false,
    this.height,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final IconData? trailingIcon;

  /// When true (default) the button stretches to fill its parent's width.
  final bool expanded;
  final bool loading;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final double h = height ?? AppDimens.buttonHeight;
    final bool enabled = onPressed != null && !loading;

    final Color fg = switch (variant) {
      AppButtonVariant.gradient => AppColors.onPrimary,
      AppButtonVariant.white => AppColors.background,
      AppButtonVariant.outlined => AppColors.textPrimary,
      AppButtonVariant.ghost => AppColors.textPrimary,
    };

    final TextStyle labelStyle =
        (Theme.of(context).textTheme.titleMedium ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w600,
      color: fg,
    );

    Widget content = loading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: fg),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: labelStyle,
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: 8),
                Icon(trailingIcon, size: 20, color: fg),
              ],
            ],
          );

    final BorderRadius radius = AppRadii.rPill;

    BoxDecoration decoration;
    switch (variant) {
      case AppButtonVariant.gradient:
        decoration = BoxDecoration(
          gradient: AppGradients.cta,
          borderRadius: radius,
          boxShadow: AppStyleTokens.elevationStyle == 'flat'
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primaryGradientEnd.withValues(alpha: 0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
        );
        break;
      case AppButtonVariant.white:
        decoration = BoxDecoration(
          color: AppColors.ctaLight,
          borderRadius: radius,
        );
        break;
      case AppButtonVariant.outlined:
        decoration = BoxDecoration(
          color: Colors.transparent,
          borderRadius: radius,
          border: Border.all(color: AppColors.primary, width: 1.5),
        );
        break;
      case AppButtonVariant.ghost:
        decoration = BoxDecoration(
          color: AppColors.surface,
          borderRadius: radius,
        );
        break;
    }

    Widget button = Opacity(
      opacity: enabled ? 1 : 0.5,
      child: DecoratedBox(
        decoration: decoration,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: enabled ? onPressed : null,
            child: Container(
              height: h,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: content,
            ),
          ),
        ),
      ),
    );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
