import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';

/// A selectable display language for the Language screen.
@immutable
class AppLanguage {
  const AppLanguage(this.code, this.nativeName, this.englishName);

  /// BCP-47 / locale code, e.g. `de`.
  final String code;

  /// Name written in its own script (primary label).
  final String nativeName;

  /// English name (secondary label).
  final String englishName;

  /// The [Locale] this language maps onto (drives `MaterialApp.locale`).
  Locale get locale => Locale(code);

  /// Whether this language is written right-to-left. Selecting one (e.g.
  /// Arabic) mirrors the whole UI via a top-level [Directionality].
  bool get isRtl => const {'ar', 'he', 'fa', 'ur'}.contains(code);
}

/// The supported display languages.
///
/// The app ships English only: the picker previously listed 16 languages but
/// shipped no translation bundles, so selecting one left the UI in English
/// (App Store Guideline 2.3). Until real `.arb` translations exist the list is
/// reduced to the single English entry. Re-add entries here as their bundles
/// land — the [AppLanguage] class and RTL logic are kept for that future.
class Languages {
  Languages._();

  static const AppLanguage fallback = AppLanguage('en', 'English', 'English');

  static const List<AppLanguage> all = <AppLanguage>[
    AppLanguage('en', 'English', 'English'),
  ];

  static AppLanguage byCode(String? code) => all.firstWhere(
        (l) => l.code == code,
        orElse: () => fallback,
      );
}
