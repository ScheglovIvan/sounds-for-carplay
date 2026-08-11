import 'package:flutter/material.dart';

import 'package:drivana/core/app_state.dart';
import 'package:drivana/core/models/user_settings.dart';
import 'package:drivana/ui/components/components.dart';

/// Appearance / theme settings screen (app_spec id "0009").
///
/// Lets the user follow the device setting or pin a Dark / Light look. The
/// choice writes through [AppState.setThemeOption], which drives the root
/// [MaterialApp]'s [ThemeMode]. Composed only from the shared design system;
/// copy is paraphrased and icons use the app's own rounded Material set.
class Screen_0009 extends StatelessWidget {
  const Screen_0009({super.key});

  static const Map<AppThemeOption, String> _blurb = <AppThemeOption, String>{
    AppThemeOption.system: 'Follow your phone\'s light or dark setting.',
    AppThemeOption.dark: 'A deep, low-glare look for night drives.',
    AppThemeOption.light: 'Bright and crisp for daytime use.',
  };

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return AppScaffold(
      topBar: const AppTopBar(title: 'Appearance', showBack: true),
      body: ValueListenableBuilder<ThemeMode>(
        valueListenable: AppState.themeMode,
        builder: (context, mode, _) {
          final AppThemeOption selected = AppThemeOption.fromThemeMode(mode);
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.gutter,
              8,
              AppDimens.gutter,
              24,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12, top: 4),
                child: Text(
                  'Choose how the app looks. Match your device, or lock in a '
                  'style you prefer.',
                  style: text.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
              const AppSectionHeader(title: 'Theme'),
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    for (int i = 0; i < AppThemeOption.values.length; i++) ...[
                      if (i != 0) const _RowDivider(),
                      AppListTile(
                        leadingIcon: AppThemeOption.values[i].icon,
                        leadingColor: AppColors.primary,
                        title: AppThemeOption.values[i].label,
                        subtitle: _blurb[AppThemeOption.values[i]],
                        showChevron: false,
                        trailing: _SelectMark(
                          selected:
                              AppThemeOption.values[i] == selected,
                        ),
                        onTap: () =>
                            AppState.setThemeOption(AppThemeOption.values[i]),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SelectMark extends StatelessWidget {
  const _SelectMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Icon(
      selected ? Icons.check_circle_rounded : Icons.circle_outlined,
      color: selected ? AppColors.primary : AppColors.textSecondary,
      size: 24,
    );
  }
}

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
