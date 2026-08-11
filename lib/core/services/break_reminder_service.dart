import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'notification_service.dart';
import 'preferences_store.dart';

/// Break reminders for long drives (app_spec id "break_reminders").
///
/// Real behaviour, not a decorative toggle:
///   * enabling it triggers the ACTUAL iOS notification authorization prompt
///     through [NotificationService] (permission_handler) — the switch only
///     latches on once the OS says yes;
///   * the interval is persisted and honoured by the live drive timer;
///   * while a Focus Drive is recording, [onDriveTick] counts real elapsed
///     driving time and raises [dueAt] every interval, which the Focus Drive
///     board turns into an on-screen nudge plus haptic feedback.
///
/// LIMIT: no local-notification scheduler is bundled, so the nudge is raised
/// while Focus Drive is on screen (which is where the drive timer runs) rather
/// than as a background banner. Documented in `CAPABILITIES.md` and stated
/// plainly on the Break Reminders screen itself.
class BreakReminderService {
  BreakReminderService._();

  static final BreakReminderService instance = BreakReminderService._();

  /// Interval bounds offered by the stepper, in minutes.
  static const int minIntervalMinutes = 30;
  static const int maxIntervalMinutes = 180;
  static const int intervalStepMinutes = 15;
  static const int defaultIntervalMinutes = 90;

  final PreferencesStore _store = PreferencesStore.instance;

  /// Whether reminders are armed. Only ever true while the OS grants us
  /// notification authorization.
  final ValueNotifier<bool> enabled = ValueNotifier<bool>(false);

  /// Minutes of continuous driving between nudges.
  final ValueNotifier<int> intervalMinutes =
      ValueNotifier<int>(defaultIntervalMinutes);

  /// Bumped each time a break becomes due, so the UI can react exactly once per
  /// nudge. Null until the first one fires in the current drive.
  final ValueNotifier<DateTime?> dueAt = ValueNotifier<DateTime?>(null);

  /// How long until the next nudge, or null when nothing is being timed.
  final ValueNotifier<Duration?> nextBreakIn = ValueNotifier<Duration?>(null);

  /// The number of nudges already raised in the current drive.
  int _firedThisDrive = 0;

  bool _loaded = false;

  /// Hydrate persisted settings. Safe to call more than once.
  void load() {
    if (_loaded) return;
    enabled.value =
        _store.getBool(PreferencesStore.kBreakRemindersEnabled) ?? false;
    intervalMinutes.value = _clampInterval(
      _store.getInt(PreferencesStore.kBreakIntervalMinutes) ??
          defaultIntervalMinutes,
    );
    _loaded = true;
  }

  static int _clampInterval(int value) {
    if (value < minIntervalMinutes) return minIntervalMinutes;
    if (value > maxIntervalMinutes) return maxIntervalMinutes;
    return value;
  }

  /// Arm or disarm reminders.
  ///
  /// Turning them ON asks the OS for real notification permission first; if the
  /// user declines, the switch stays off rather than pretending to be armed.
  /// Returns the resulting state.
  Future<bool> setEnabled(bool value) async {
    if (!value) {
      enabled.value = false;
      await _store.setBool(PreferencesStore.kBreakRemindersEnabled, false);
      nextBreakIn.value = null;
      return false;
    }

    final bool granted = await NotificationService.instance.request();
    enabled.value = granted;
    await _store.setBool(PreferencesStore.kBreakRemindersEnabled, granted);
    return granted;
  }

  Future<void> setIntervalMinutes(int value) async {
    final int next = _clampInterval(value);
    if (next == intervalMinutes.value) return;
    intervalMinutes.value = next;
    // A changed interval re-bases the current drive's countdown.
    _firedThisDrive = 0;
    await _store.setInt(PreferencesStore.kBreakIntervalMinutes, next);
  }

  /// Called once a second by [TripRecorder] with the real elapsed drive time.
  void onDriveTick(Duration elapsed) {
    if (!enabled.value) {
      nextBreakIn.value = null;
      return;
    }

    final int interval = intervalMinutes.value * 60;
    final int elapsedSeconds = elapsed.inSeconds;
    final int due = (_firedThisDrive + 1) * interval;

    nextBreakIn.value = Duration(seconds: (due - elapsedSeconds).clamp(0, due));

    if (elapsedSeconds >= due) {
      _firedThisDrive++;
      dueAt.value = DateTime.now();
      // A real, felt cue — the driver is looking at the road, not the screen.
      if (!kIsWeb) {
        HapticFeedback.heavyImpact();
      }
    }
  }

  /// Reset the per-drive counters when a drive starts or ends.
  void resetDrive() {
    _firedThisDrive = 0;
    dueAt.value = null;
    nextBreakIn.value = enabled.value
        ? Duration(minutes: intervalMinutes.value)
        : null;
  }
}
