import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A single category filter chip (All, Trends, Gaming, Cinematic, Engine, …).
///
/// Selected chips fill with the primary token; unselected chips use the surface
/// color. Corner is `radius_pill`.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final Color fg = selected ? AppColors.onPrimary : AppColors.textSecondary;
    final TextStyle style =
        (Theme.of(context).textTheme.labelLarge ?? const TextStyle()).copyWith(
      color: fg,
      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
    );

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: AppRadii.rPill,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: AppRadii.rPill,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: fg),
                const SizedBox(width: 6),
              ],
              Text(label, style: style),
            ],
          ),
        ),
      ),
    );
  }
}

/// A horizontally scrolling row of [AppChip]s bound to a selected index.
class AppChipBar extends StatelessWidget {
  const AppChipBar({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.padding =
        const EdgeInsets.symmetric(horizontal: AppDimens.gutter),
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) => AppChip(
          label: labels[i],
          selected: i == selectedIndex,
          onTap: () => onSelected(i),
        ),
      ),
    );
  }
}
