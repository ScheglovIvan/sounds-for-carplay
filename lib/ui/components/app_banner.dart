import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A soft inline notice banner (e.g. the "activation not enabled yet" tip).
///
/// The [AppBannerTone.warning] variant uses the `warning_bg` / `warning_text`
/// tokens; [AppBannerTone.info] uses a translucent primary surface.
enum AppBannerTone { warning, info }

class AppBanner extends StatelessWidget {
  const AppBanner({
    super.key,
    required this.message,
    this.title,
    this.icon = Icons.info_outline_rounded,
    this.tone = AppBannerTone.warning,
    this.onTap,
    this.trailing,
  });

  final String message;
  final String? title;
  final IconData icon;
  final AppBannerTone tone;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final bool warning = tone == AppBannerTone.warning;
    final Color bg =
        warning ? AppColors.warningBg : AppColors.primary.withValues(alpha: 0.14);
    final Color fg = warning ? AppColors.warningText : AppColors.textPrimary;

    final TextStyle titleStyle =
        (Theme.of(context).textTheme.labelLarge ?? const TextStyle()).copyWith(
      color: fg,
      fontWeight: FontWeight.w700,
    );
    final TextStyle msgStyle =
        (Theme.of(context).textTheme.bodySmall ?? const TextStyle()).copyWith(
      color: fg.withValues(alpha: 0.9),
    );

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: fg, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (title != null) ...[
                      Text(title!, style: titleStyle),
                      const SizedBox(height: 3),
                    ],
                    Text(message, style: msgStyle),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
