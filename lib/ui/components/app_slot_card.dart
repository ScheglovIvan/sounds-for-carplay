import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_card.dart';

/// A drive "cue slot" card — Departure / Arrival / Home.
///
/// Shows a tinted round glyph, the slot title, the currently assigned sound
/// name (or an empty-state subtitle like "No sound selected"), and a trailing
/// chevron. Tapping opens the sound picker.
class AppSlotCard extends StatelessWidget {
  const AppSlotCard({
    super.key,
    required this.title,
    required this.icon,
    this.glyphColor,
    this.selectedSound,
    this.emptyLabel = 'No sound selected',
    this.onTap,
    this.trailingIcon = Icons.chevron_right_rounded,
  });

  final String title;
  final IconData icon;
  final Color? glyphColor;
  final String? selectedSound;
  final String emptyLabel;
  final VoidCallback? onTap;
  final IconData trailingIcon;

  @override
  Widget build(BuildContext context) {
    final Color glyph = glyphColor ?? AppColors.primary;
    final bool hasSound = selectedSound != null && selectedSound!.isNotEmpty;

    final TextStyle titleStyle =
        (Theme.of(context).textTheme.titleMedium ?? const TextStyle()).copyWith(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w600,
    );
    final TextStyle subStyle =
        (Theme.of(context).textTheme.bodyMedium ?? const TextStyle()).copyWith(
      color: hasSound ? AppColors.primary : AppColors.textSecondary,
    );

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: glyph.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: glyph, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: titleStyle),
                const SizedBox(height: 3),
                Text(
                  hasSound ? selectedSound! : emptyLabel,
                  style: subStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(trailingIcon, color: AppColors.textSecondary, size: 24),
        ],
      ),
    );
  }
}
