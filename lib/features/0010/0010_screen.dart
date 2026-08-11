import 'package:flutter/material.dart';

import 'package:drivana/core/app_state.dart';
import 'package:drivana/core/models/user_settings.dart';
import 'package:drivana/ui/components/components.dart';

/// Measurement-unit settings screen (app_spec id "0010").
///
/// Three independent single-select groups — speed & distance, tyre pressure and
/// temperature — that feed how the dashboard and weather values are formatted.
/// Each choice persists through the matching `AppState.setUnit*` method.
/// Composed only from the shared design system; copy is paraphrased.
class Screen_0010 extends StatelessWidget {
  const Screen_0010({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return AppScaffold(
      topBar: const AppTopBar(title: 'Measurement Units', showBack: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppDimens.gutter,
          8,
          AppDimens.gutter,
          24,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4, top: 4),
            child: Text(
              'Set the units you\'d like readings shown in across the app.',
              style: text.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ),

          // Speed & distance.
          const AppSectionHeader(title: 'Speed & Distance'),
          ValueListenableBuilder<SpeedUnit>(
            valueListenable: AppState.unitSpeed,
            builder: (context, current, _) => _ChoiceCard(
              children: [
                for (final SpeedUnit u in SpeedUnit.values)
                  _ChoiceRow(
                    title: u.label,
                    subtitle: u.detail,
                    selected: u == current,
                    onTap: () => AppState.setSpeedUnit(u),
                  ),
              ],
            ),
          ),

          // Tyre pressure.
          const AppSectionHeader(title: 'Tyre Pressure'),
          ValueListenableBuilder<PressureUnit>(
            valueListenable: AppState.unitPressure,
            builder: (context, current, _) => _ChoiceCard(
              children: [
                for (final PressureUnit u in PressureUnit.values)
                  _ChoiceRow(
                    title: u.label,
                    selected: u == current,
                    onTap: () => AppState.setPressureUnit(u),
                  ),
              ],
            ),
          ),

          // Temperature.
          const AppSectionHeader(title: 'Temperature'),
          ValueListenableBuilder<TemperatureUnit>(
            valueListenable: AppState.unitTemperature,
            builder: (context, current, _) => _ChoiceCard(
              children: [
                for (final TemperatureUnit u in TemperatureUnit.values)
                  _ChoiceRow(
                    title: u.label,
                    selected: u == current,
                    onTap: () => AppState.setTemperatureUnit(u),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Wraps a set of [_ChoiceRow]s in a grouped card with hairline separators.
class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = [];
    for (int i = 0; i < children.length; i++) {
      if (i != 0) rows.add(const _RowDivider());
      rows.add(children[i]);
    }
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(children: rows),
    );
  }
}

/// A single selectable unit option.
class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppListTile(
      title: title,
      subtitle: subtitle,
      showChevron: false,
      onTap: onTap,
      trailing: Icon(
        selected ? Icons.check_circle_rounded : Icons.circle_outlined,
        color: selected ? AppColors.primary : AppColors.textSecondary,
        size: 24,
      ),
    );
  }
}

/// A hairline separator between rows inside a grouped card.
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppDimens.gutter),
      child: Divider(
        height: 1,
        thickness: 1,
        color: AppColors.textSecondary.withValues(alpha: 0.14),
      ),
    );
  }
}
