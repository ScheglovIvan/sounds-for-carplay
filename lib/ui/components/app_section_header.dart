import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A titled section header with an optional trailing action ("See all").
/// Used above grouped lists, slot sections and settings groups.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(
      AppDimens.gutter,
      AppDimens.gutter,
      AppDimens.gutter,
      8,
    ),
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle =
        (Theme.of(context).textTheme.titleMedium ?? const TextStyle()).copyWith(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w600,
    );

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(child: Text(title, style: titleStyle)),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: (Theme.of(context).textTheme.labelLarge ??
                        const TextStyle())
                    .copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}
