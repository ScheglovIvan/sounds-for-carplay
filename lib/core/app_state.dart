import 'package:flutter/material.dart';

import 'data/languages.dart';
import 'models/sound.dart';
import 'models/subscription.dart';
import 'models/user_settings.dart';
import 'services/preferences_store.dart';

/// App-wide, lightweight reactive state shared across every screen.
///
/// Built on plain [ValueNotifier]s (no external state-management package) so
/// screens can `ValueListenableBuilder` over exactly what they need. All state
/// is hydrated from and written through to on-device storage via
/// [PreferencesStore] — except the PRO entitlement, which is never persisted and
/// flows in through [applyEntitlement] straight from Apphud (see
/// `ApphudService`).
///
/// Mutations should go through the `set*` / `select*` methods so persistence
/// stays in sync — read directly from the notifiers.
class AppState {
  AppState._();

  static final PreferencesStore _store = PreferencesStore.instance;
  static bool _loaded = false;

  // ── Theme ──────────────────────────────────────────────────────────────────
  /// Active [ThemeMode] the root [MaterialApp] listens to. Dark-first default.
  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier<ThemeMode>(ThemeMode.dark);

  /// The Theme screen's selected option, derived from [themeMode].
  static AppThemeOption get themeOption =>
      AppThemeOption.fromThemeMode(themeMode.value);

  static void setThemeOption(AppThemeOption option) {
    themeMode.value = option.themeMode;
    _store.setString(PreferencesStore.kThemeOption, option.key);
  }

  // ── Entitlement (PRO) ───────────────────────────────────────────────────────
  /// Resolved PRO entitlement. Screens that only need the boolean can listen to
  /// [isPro] instead.
  ///
  /// This is an in-memory mirror of Apphud's answer, never a stored flag: the
  /// single source of truth is `Apphud.hasPremiumAccess()`, re-read at launch,
  /// on resume and after every purchase/restore by [ApphudService]. Nothing here
  /// is persisted, so a lapsed subscription can never keep PRO alive on device.
  static final ValueNotifier<Entitlement> entitlement =
      ValueNotifier<Entitlement>(Entitlement.free);

  /// Convenience mirror of `entitlement.value.isActive` for simple gates.
  static final ValueNotifier<bool> isPro = ValueNotifier<bool>(false);

  /// Apply an entitlement resolved from Apphud. Notifying [isPro] is what makes
  /// locked content unlock immediately after a purchase, with no app restart.
  static void applyEntitlement(Entitlement value) {
    entitlement.value = value;
    isPro.value = value.isActive;
  }

  // ── Sound slots ─────────────────────────────────────────────────────────────
  /// Selected sound id per slot (null = "No sound selected").
  static final ValueNotifier<Map<SoundSlotType, String?>> slotSelections =
      ValueNotifier<Map<SoundSlotType, String?>>({
    SoundSlotType.connection: null,
    SoundSlotType.disconnection: null,
    SoundSlotType.homeArrival: null,
  });

  /// The sound id currently assigned to [slot], or null.
  static String? selectedSoundId(SoundSlotType slot) =>
      slotSelections.value[slot];

  /// Assign [soundId] (or null to clear) to [slot] and persist it.
  static void selectSound(SoundSlotType slot, String? soundId) {
    final next = Map<SoundSlotType, String?>.from(slotSelections.value);
    next[slot] = soundId;
    slotSelections.value = next;
    _store.setString(_slotKey(slot), soundId);
  }

  static void clearSlot(SoundSlotType slot) => selectSound(slot, null);

  static String _slotKey(SoundSlotType slot) {
    switch (slot) {
      case SoundSlotType.connection:
        return PreferencesStore.kSlotConnection;
      case SoundSlotType.disconnection:
        return PreferencesStore.kSlotDisconnection;
      case SoundSlotType.homeArrival:
        return PreferencesStore.kSlotHomeArrival;
    }
  }

  // ── Preferences: language ────────────────────────────────────────────────────
  static final ValueNotifier<AppLanguage> language =
      ValueNotifier<AppLanguage>(Languages.fallback);

  static void setLanguage(AppLanguage value) {
    language.value = value;
    _store.setString(PreferencesStore.kLanguage, value.code);
  }

  // ── Preferences: units ───────────────────────────────────────────────────────
  static final ValueNotifier<SpeedUnit> unitSpeed =
      ValueNotifier<SpeedUnit>(SpeedUnit.metric);
  static final ValueNotifier<PressureUnit> unitPressure =
      ValueNotifier<PressureUnit>(PressureUnit.kpa);
  static final ValueNotifier<TemperatureUnit> unitTemperature =
      ValueNotifier<TemperatureUnit>(TemperatureUnit.celsius);

  static void setSpeedUnit(SpeedUnit value) {
    unitSpeed.value = value;
    _store.setString(PreferencesStore.kUnitSpeed, value.key);
  }

  static void setPressureUnit(PressureUnit value) {
    unitPressure.value = value;
    _store.setString(PreferencesStore.kUnitPressure, value.key);
  }

  static void setTemperatureUnit(TemperatureUnit value) {
    unitTemperature.value = value;
    _store.setString(PreferencesStore.kUnitTemperature, value.key);
  }

  // ── Preferences: notifications ───────────────────────────────────────────────
  static final ValueNotifier<bool> notificationsEnabled =
      ValueNotifier<bool>(false);

  static void setNotificationsEnabled(bool value) {
    notificationsEnabled.value = value;
    _store.setBool(PreferencesStore.kNotifications, value);
  }

  // ── Onboarding ──────────────────────────────────────────────────────────────
  static final ValueNotifier<bool> onboardingComplete =
      ValueNotifier<bool>(false);

  static void completeOnboarding() {
    onboardingComplete.value = true;
    _store.setBool(PreferencesStore.kOnboardingComplete, true);
  }

  // ── Hydration ───────────────────────────────────────────────────────────────
  /// Load all persisted state from disk. Safe to call more than once; only the
  /// first call touches storage.
  static Future<void> load() async {
    if (_loaded) return;
    await _store.ensureLoaded();

    // Theme.
    themeMode.value =
        AppThemeOption.fromKey(_store.getString(PreferencesStore.kThemeOption))
            .themeMode;

    // Entitlement is NOT hydrated from disk — Apphud is the only source of
    // truth. Purge any grant written by an earlier build so it can never act as
    // a local stand-in for a real subscription.
    _store.setJson(PreferencesStore.kEntitlement, null);

    // Sound slots.
    slotSelections.value = {
      SoundSlotType.connection:
          _store.getString(PreferencesStore.kSlotConnection),
      SoundSlotType.disconnection:
          _store.getString(PreferencesStore.kSlotDisconnection),
      SoundSlotType.homeArrival:
          _store.getString(PreferencesStore.kSlotHomeArrival),
    };

    // Preferences.
    language.value =
        Languages.byCode(_store.getString(PreferencesStore.kLanguage));
    unitSpeed.value =
        SpeedUnit.fromKey(_store.getString(PreferencesStore.kUnitSpeed));
    unitPressure.value =
        PressureUnit.fromKey(_store.getString(PreferencesStore.kUnitPressure));
    unitTemperature.value = TemperatureUnit.fromKey(
        _store.getString(PreferencesStore.kUnitTemperature));
    notificationsEnabled.value =
        _store.getBool(PreferencesStore.kNotifications) ?? false;
    onboardingComplete.value =
        _store.getBool(PreferencesStore.kOnboardingComplete) ?? false;

    _loaded = true;
  }
}
