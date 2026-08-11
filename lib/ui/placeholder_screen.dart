import 'package:flutter/material.dart';

import 'components/app_icon_mark.dart';
import 'theme/app_theme.dart';

/// Shared visual for the parallel-safe screen placeholders created by the
/// scaffold. A later screen task overwrites each `lib/features/<id>/` widget
/// with the real UI; until then this renders a standalone, themed stub so the
/// route (and the `/screen/<id>` web preview) works on its own.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.screenId,
    required this.title,
  });

  final String screenId;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.gutter * 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // The app's own badge — its real launcher icon.
              const AppIconMark(size: 84),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Screen "$screenId"',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
