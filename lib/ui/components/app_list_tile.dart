import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A generic settings / menu row: a leading icon (optionally in a tinted
/// rounded square), a title, optional subtitle, an optional trailing value or
/// widget and a chevron. Used by Settings, the drawer and grouped lists.
class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.leadingColor,
    this.leading,
    this.trailingText,
    this.trailing,
    this.showChevron = true,
    this.onTap,
    this.dense = false,
  });

  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final Color? leadingColor;
  final Widget? leading;
  final String? trailingText;
  final Widget? trailing;
  final bool showChevron;
  final VoidCallback? onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle =
        (Theme.of(context).textTheme.bodyLarge ?? const TextStyle()).copyWith(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w500,
    );
    final TextStyle subStyle =
        (Theme.of(context).textTheme.bodySmall ?? const TextStyle()).copyWith(
      color: AppColors.textSecondary,
    );

    Widget? lead = leading;
    if (lead == null && leadingIcon != null) {
      final Color c = leadingColor ?? AppColors.primary;
      lead = Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        child: Icon(leadingIcon, color: c, size: 20),
      );
    }

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppDimens.gutter,
            vertical: dense ? 10 : 14,
          ),
          child: Row(
            children: [
              if (lead != null) ...[
                lead,
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: titleStyle),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: subStyle),
                    ],
                  ],
                ),
              ),
              if (trailingText != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(trailingText!, style: subStyle),
                ),
              if (trailing != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: trailing!,
                ),
              if (showChevron)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(Icons.chevron_right_rounded,
                      color: AppColors.textSecondary, size: 22),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
