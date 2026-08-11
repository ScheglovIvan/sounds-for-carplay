import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_badge.dart';

/// A single row in the sound library / picker list.
///
/// Left: a circular play/pause preview button (tints with the primary token
/// while playing). Middle: the sound title and its category/subtitle, plus an
/// optional PREMIUM tag for locked sounds. Right: a radio-style selection
/// control OR a lock glyph when premium & not entitled.
class AppSoundRow extends StatelessWidget {
  const AppSoundRow({
    super.key,
    required this.title,
    this.subtitle,
    this.selected = false,
    this.playing = false,
    this.premium = false,
    this.locked = false,
    this.onPlayToggle,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final bool playing;

  /// Marks the sound as PRO-only (shows a PREMIUM tag).
  final bool premium;

  /// When true the user is not entitled — trailing shows a lock instead of a
  /// radio, and tapping should route to the paywall.
  final bool locked;
  final VoidCallback? onPlayToggle;
  final VoidCallback? onTap;

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

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.gutter,
            vertical: 10,
          ),
          child: Row(
            children: [
              // Preview play/pause control.
              GestureDetector(
                onTap: onPlayToggle,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: playing
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: 0.16),
                  ),
                  child: Icon(
                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: playing ? AppColors.onPrimary : AppColors.primary,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: titleStyle,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (premium) ...[
                          const SizedBox(width: 8),
                          const AppBadge(
                            label: 'PRO',
                            tone: AppBadgeTone.premium,
                          ),
                        ],
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: subStyle),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _trailing(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _trailing() {
    if (locked) {
      return Icon(Icons.lock_rounded,
          color: AppColors.textSecondary, size: 22);
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.primary : Colors.transparent,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.textSecondary,
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded,
              color: AppColors.onPrimary, size: 15)
          : null,
    );
  }
}
