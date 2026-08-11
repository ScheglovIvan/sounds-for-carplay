import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Small pill badge for discounts ("89% OFF"), "FREE"/"PREMIUM" tags and
/// generic status labels. Color is chosen from tokens via [tone].
enum AppBadgeTone { accent, primary, premium, neutral, success }

class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.tone = AppBadgeTone.accent,
    this.icon,
  });

  final String label;
  final AppBadgeTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;
    switch (tone) {
      case AppBadgeTone.accent:
        bg = AppColors.accentBadge;
        fg = AppColors.onPrimary;
        break;
      case AppBadgeTone.primary:
        bg = AppColors.primary;
        fg = AppColors.onPrimary;
        break;
      case AppBadgeTone.premium:
        bg = AppColors.proGradientStart;
        fg = AppColors.background;
        break;
      case AppBadgeTone.success:
        bg = AppColors.success;
        fg = AppColors.onPrimary;
        break;
      case AppBadgeTone.neutral:
        bg = AppColors.surface;
        fg = AppColors.textSecondary;
        break;
    }

    final TextStyle style =
        (Theme.of(context).textTheme.labelSmall ?? const TextStyle()).copyWith(
      color: fg,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.3,
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: icon == null ? 10 : 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(label, style: style),
        ],
      ),
    );
  }
}
