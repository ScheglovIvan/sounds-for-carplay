import 'package:flutter/material.dart';

/// Speed & distance unit system (drives dashboard/weather formatting).
enum SpeedUnit {
  metric('metric', 'Metric', 'km/h, km'),
  imperial('imperial', 'Imperial', 'mph, miles');

  const SpeedUnit(this.key, this.label, this.detail);
  final String key;
  final String label;
  final String detail;

  static SpeedUnit fromKey(String? k) =>
      SpeedUnit.values.firstWhere((e) => e.key == k, orElse: () => SpeedUnit.metric);
}

/// Tyre-pressure unit system.
enum PressureUnit {
  kpa('kpa', 'kPa / L'),
  psi('psi', 'PSI');

  const PressureUnit(this.key, this.label);
  final String key;
  final String label;

  static PressureUnit fromKey(String? k) => PressureUnit.values
      .firstWhere((e) => e.key == k, orElse: () => PressureUnit.kpa);
}

/// Temperature unit system.
enum TemperatureUnit {
  celsius('c', '°C'),
  fahrenheit('f', '°F');

  const TemperatureUnit(this.key, this.label);
  final String key;
  final String label;

  static TemperatureUnit fromKey(String? k) => TemperatureUnit.values
      .firstWhere((e) => e.key == k, orElse: () => TemperatureUnit.celsius);
}

/// The three theme options shown on the Theme screen. Maps onto Flutter's
/// [ThemeMode] but carries its own persistence key, label and icon.
enum AppThemeOption {
  system('system', 'Match Device', Icons.smartphone_rounded, ThemeMode.system),
  dark('dark', 'Dark', Icons.dark_mode_rounded, ThemeMode.dark),
  light('light', 'Light', Icons.light_mode_rounded, ThemeMode.light);

  const AppThemeOption(this.key, this.label, this.icon, this.themeMode);
  final String key;
  final String label;
  final IconData icon;
  final ThemeMode themeMode;

  static AppThemeOption fromKey(String? k) => AppThemeOption.values
      .firstWhere((e) => e.key == k, orElse: () => AppThemeOption.dark);

  static AppThemeOption fromThemeMode(ThemeMode m) => AppThemeOption.values
      .firstWhere((e) => e.themeMode == m, orElse: () => AppThemeOption.dark);
}
