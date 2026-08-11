import 'package:flutter/material.dart';

import '../../ui/components/components.dart';

/// Shows a themed PRIMING sheet before a real OS permission dialog and resolves
/// to whether the user chose to go on.
///
/// This never grants anything itself — the caller must follow a `true` result
/// with the actual system request (see `LocationService` / `NotificationService`).
///
/// App Store 5.1.1(iv): a custom pre-permission screen may explain WHY access
/// helps, but must not tell the user how to answer the system dialog. The
/// continue button therefore defaults to the neutral "Continue" — never
/// "Allow" or "Enable".
Future<bool> requestPermission(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String message,
  String continueLabel = 'Continue',
  String denyLabel = 'Not Now',
}) async {
  final bool? granted = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (ctx) => _PermissionDialog(
      icon: icon,
      title: title,
      message: message,
      continueLabel: continueLabel,
      denyLabel: denyLabel,
    ),
  );
  return granted ?? false;
}

class _PermissionDialog extends StatelessWidget {
  const _PermissionDialog({
    required this.icon,
    required this.title,
    required this.message,
    required this.continueLabel,
    required this.denyLabel,
  });

  final IconData icon;
  final String title;
  final String message;
  final String continueLabel;
  final String denyLabel;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      shape: RoundedRectangleBorder(borderRadius: AppRadii.rLg),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 34),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: (text.titleMedium ?? const TextStyle()).copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: (text.bodyMedium ?? const TextStyle())
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 22),
            AppButton(
              label: continueLabel,
              variant: AppButtonVariant.gradient,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 10),
            AppButton(
              label: denyLabel,
              variant: AppButtonVariant.ghost,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
