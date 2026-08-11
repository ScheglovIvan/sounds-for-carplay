import '../models/user_settings.dart';

/// Formatting helpers that turn raw metric source values into display strings
/// honoring the user's chosen units (see the Units screen and the
/// `AppState.unit*` notifiers).
///
/// The dashboard/driving-mode tiles hold their sample data in metric and route
/// it through here, so flipping the Units setting re-renders those tiles in the
/// selected system instead of showing frozen values.
class UnitsFormat {
  UnitsFormat._();

  /// Format a Celsius temperature into the chosen unit.
  ///
  /// [degreeOnly] renders just `21°` (glanceable tile); otherwise the unit
  /// letter is appended (`21°C` / `70°F`).
  static String temperature(
    double celsius,
    TemperatureUnit unit, {
    bool degreeOnly = true,
  }) {
    final double value =
        unit == TemperatureUnit.fahrenheit ? celsius * 9 / 5 + 32 : celsius;
    final int rounded = value.round();
    if (degreeOnly) return '$rounded°';
    return '$rounded${unit == TemperatureUnit.fahrenheit ? '°F' : '°C'}';
  }

  /// Format a distance given in kilometres into the chosen unit, e.g.
  /// `6.4 km` / `4 mi`.
  static String distance(double km, SpeedUnit unit) {
    if (unit == SpeedUnit.imperial) {
      return '${_trim(km * 0.621371)} mi';
    }
    return '${_trim(km)} km';
  }

  /// Short distance-unit suffix for the current system (`km` / `mi`).
  static String distanceSuffix(SpeedUnit unit) =>
      unit == SpeedUnit.imperial ? 'mi' : 'km';

  static String _trim(double v) {
    final String s = v.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }
}
