import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thin, typed wrapper over [SharedPreferences] for on-device persistence.
///
/// Holds every persisted key in one place so [AppState] can hydrate on launch
/// and write through on each change. All reads are null-safe with sensible
/// fallbacks; writes are best-effort (failures are swallowed so a storage error
/// never crashes the UI).
class PreferencesStore {
  PreferencesStore._();

  static final PreferencesStore instance = PreferencesStore._();

  SharedPreferences? _prefs;
  bool get isReady => _prefs != null;

  // ── Keys ──────────────────────────────────────────────────────────────────
  static const String kThemeOption = 'settings.theme';
  static const String kLanguage = 'settings.language';
  static const String kUnitSpeed = 'settings.unit.speed';
  static const String kUnitPressure = 'settings.unit.pressure';
  static const String kUnitTemperature = 'settings.unit.temperature';
  static const String kNotifications = 'settings.notifications_enabled';
  static const String kSlotConnection = 'slot.connection';
  static const String kSlotDisconnection = 'slot.disconnection';
  static const String kSlotHomeArrival = 'slot.home_arrival';
  static const String kEntitlement = 'entitlement.premium';
  static const String kOnboardingComplete = 'onboarding.complete';
  static const String kBreakRemindersEnabled = 'breaks.enabled';
  static const String kBreakIntervalMinutes = 'breaks.interval_minutes';

  /// Recorded drives (a JSON envelope `{"items": [...]}` — see `TripStore`).
  static const String kTrips = 'trips.v1';

  Future<void> ensureLoaded() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // ── String ──
  String? getString(String key) => _prefs?.getString(key);

  Future<void> setString(String key, String? value) async {
    try {
      if (value == null) {
        await _prefs?.remove(key);
      } else {
        await _prefs?.setString(key, value);
      }
    } catch (e) {
      debugPrint('[prefs] failed to write $key: $e');
    }
  }

  // ── Bool ──
  bool? getBool(String key) => _prefs?.getBool(key);

  Future<void> setBool(String key, bool value) async {
    try {
      await _prefs?.setBool(key, value);
    } catch (e) {
      debugPrint('[prefs] failed to write $key: $e');
    }
  }

  // ── Int ──
  int? getInt(String key) => _prefs?.getInt(key);

  Future<void> setInt(String key, int value) async {
    try {
      await _prefs?.setInt(key, value);
    } catch (e) {
      debugPrint('[prefs] failed to write $key: $e');
    }
  }

  // ── JSON map ──
  Map<String, dynamic>? getJson(String key) {
    final raw = _prefs?.getString(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> setJson(String key, Map<String, dynamic>? value) async {
    if (value == null) {
      await setString(key, null);
    } else {
      await setString(key, jsonEncode(value));
    }
  }
}
