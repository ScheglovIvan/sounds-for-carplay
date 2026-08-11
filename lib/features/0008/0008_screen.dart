import 'package:flutter/material.dart';

import 'package:drivana/core/app_state.dart';
import 'package:drivana/core/data/languages.dart';
import 'package:drivana/ui/components/components.dart';

/// Language settings screen (app_spec id "0008").
///
/// A single-select list of display languages. The chosen language persists
/// through [AppState.setLanguage]; the row updates in place with a radio mark.
/// Composed only from the shared design system; copy is paraphrased and icons
/// use the app's own rounded Material set per the anti-clone rules.
class Screen_0008 extends StatelessWidget {
  const Screen_0008({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return AppScaffold(
      topBar: const AppTopBar(title: 'Display Language', showBack: true),
      body: ValueListenableBuilder<AppLanguage>(
        valueListenable: AppState.language,
        builder: (context, current, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.gutter,
              8,
              AppDimens.gutter,
              24,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16, top: 4),
                child: Text(
                  'Pick the language you\'d like the app shown in. You can '
                  'switch back any time.',
                  style: text.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    for (int i = 0; i < Languages.all.length; i++) ...[
                      if (i != 0) const _RowDivider(),
                      AppListTile(
                        title: Languages.all[i].nativeName,
                        subtitle: Languages.all[i].englishName,
                        showChevron: false,
                        trailing: _SelectMark(
                          selected:
                              Languages.all[i].code == current.code,
                        ),
                        onTap: () => AppState.setLanguage(Languages.all[i]),
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

/// A radio-style trailing indicator shared by the settings selection rows.
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
