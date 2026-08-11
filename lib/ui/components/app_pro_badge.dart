import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The "GET PRO" / "Go Premium" gradient badge shown in nav bars and gates.
///
/// Uses the `pro_gradient_start`/`pro_gradient_end` tokens. Tap it to open a
/// paywall. Two densities: [AppProBadge] (chip in a top bar) and the larger
/// pill for banners.
class AppProBadge extends StatelessWidget {
  const AppProBadge({
    super.key,
    this.label = 'GET PRO',
    this.onPressed,
    this.icon = Icons.workspace_premium_rounded,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;

  /// When true renders a smaller chip suited to a nav bar action slot.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double vPad = compact ? 6 : 9;
    final double hPad = compact ? 12 : 16;
    final double iconSize = compact ? 15 : 18;

    final TextStyle style =
        (Theme.of(context).textTheme.labelLarge ?? const TextStyle()).copyWith(
      color: AppColors.onPrimary,
      fontWeight: FontWeight.w700,
      fontSize: compact ? 12 : 14,
      letterSpacing: 0.3,
    );

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: AppRadii.rPill,
        onTap: onPressed,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          decoration: BoxDecoration(
            gradient: AppGradients.pro,
            borderRadius: AppRadii.rPill,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: iconSize, color: AppColors.onPrimary),
              const SizedBox(width: 6),
              Text(label, style: style),
            ],
          ),
        ),
      ),
    );
  }
}
