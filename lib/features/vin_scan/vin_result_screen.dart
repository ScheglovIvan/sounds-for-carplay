import 'package:flutter/material.dart';

import 'package:drivana/ui/components/components.dart';

import 'vin_service.dart';

/// The VIN lookup RESULTS screen (a separate page pushed from the VIN input
/// screen — never inline, never a popup/overlay).
///
/// Shows the REAL vehicle fields returned by the vehicle database as labelled
/// rows, with a clear top-left Back button. Composes ONLY the shared design
/// system + tokens; no bespoke styling and no hardcoded/fake vehicle data.
class VinResultScreen extends StatelessWidget {
  const VinResultScreen({super.key, required this.result});

  final VinResult result;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return AppScaffold(
      topBar: AppTopBar(
        title: 'Vehicle details',
        showBack: true,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppDimens.gutter,
          10,
          AppDimens.gutter,
          28,
        ),
        children: [
          Text(
            result.title ?? 'Vehicle identified',
            style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            result.vin,
            style: text.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (int i = 0; i < result.fields.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: AppDimens.gutter,
                      endIndent: AppDimens.gutter,
                      color: AppColors.background.withValues(alpha: 0.6),
                    ),
                  _DetailRow(field: result.fields[i]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A labelled detail row in a two-column layout: the field LABEL on the left,
/// its real VALUE on the right. Every row shares the same label-column width and
/// padding so the values line up in a clean column; a long value (e.g. a full
/// body-class description) flexes and wraps across multiple lines instead of
/// overflowing, without disturbing the alignment.
class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.field});

  final VinField field;

  /// Fixed width of the left label column so every value starts on the same
  /// vertical line, matching the original's aligned table look.
  static const double _labelWidth = 118;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.gutter,
        vertical: 14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _labelWidth,
            child: Text(
              field.label,
              style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              field.value,
              textAlign: TextAlign.right,
              style: text.bodyLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
