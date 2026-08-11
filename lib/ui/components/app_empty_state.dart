import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_button.dart';

/// A centered empty / zero-result state: a soft tinted glyph, a headline, a
/// supporting line and an optional call-to-action button. Used for empty search
/// results, no-selection states and error placeholders.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    this.icon = Icons.search_off_rounded,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle =
        (Theme.of(context).textTheme.titleMedium ?? const TextStyle()).copyWith(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w600,
    );
    final TextStyle msgStyle =
        (Theme.of(context).textTheme.bodyMedium ?? const TextStyle()).copyWith(
      color: AppColors.textSecondary,
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 40),
            ),
            const SizedBox(height: 20),
            Text(title, textAlign: TextAlign.center, style: titleStyle),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(message!, textAlign: TextAlign.center, style: msgStyle),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: 24),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                expanded: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
