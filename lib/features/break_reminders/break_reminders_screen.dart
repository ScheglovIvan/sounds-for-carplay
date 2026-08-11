import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:drivana/core/app_state.dart';
import 'package:drivana/core/router/app_router.dart';
import 'package:drivana/core/services/break_reminder_service.dart';
import 'package:drivana/core/services/notification_service.dart';
import 'package:drivana/core/services/trip_recorder.dart';
import 'package:drivana/ui/components/components.dart';

/// Break Reminders (app_spec id "break_reminders", route `/break_reminders`).
///
/// A real settings screen, not a decorative one:
///   * the enable switch triggers the ACTUAL iOS notification prompt and only
///     latches on if the OS grants it;
///   * the interval is persisted and used by the live drive timer;
///   * the timer reads [TripRecorder] — it shows the real elapsed time of a
///     Focus Drive that is recording right now, and says so plainly when none
///     is.
///
/// The screen states its one honest limit up front: the nudge is raised while
/// Focus Drive is on screen (see `CAPABILITIES.md`).
class Screen_break_reminders extends StatefulWidget {
  const Screen_break_reminders({super.key});

  @override
  State<Screen_break_reminders> createState() =>
      _Screen_break_remindersState();
}

class _Screen_break_remindersState extends State<Screen_break_reminders> {
  final BreakReminderService _breaks = BreakReminderService.instance;

  Timer? _ticker;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _breaks.load();
    // Pick up a notification permission the user changed in iOS Settings while
    // the app was backgrounded.
    unawaited(_syncPermission());
    // Refresh the live drive timer once a second while this screen is open.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// If the OS revoked notifications, reminders cannot fire — so the switch
  /// must not keep claiming they are armed.
  Future<void> _syncPermission() async {
    final bool granted = await NotificationService.instance.refresh();
    if (!granted && _breaks.enabled.value) {
      await _breaks.setEnabled(false);
    }
  }

  Future<void> _toggle(bool value) async {
    if (_busy) return;
    setState(() => _busy = true);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      final bool result = await _breaks.setEnabled(value);
      if (value && !result) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Alerts are off for Drivana, so break reminders stay off.',
              ),
            ),
          );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _step(int deltaMinutes) {
    unawaited(
      _breaks.setIntervalMinutes(_breaks.intervalMinutes.value + deltaMinutes),
    );
  }

  void _save() {
    // Every control above writes through immediately, so Save is a confirm-and-
    // close: it acknowledges the settings and returns to where the user came
    // from (Menu or the Drive tab).
    final NavigatorState nav = Navigator.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            _breaks.enabled.value
                ? 'Break reminders on — every '
                    '${_breaks.intervalMinutes.value} minutes of driving.'
                : 'Break reminders are off.',
          ),
        ),
      );
    if (nav.canPop()) {
      nav.pop();
    } else {
      AppRouter.go(context, '0007');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(
        title: 'Break Reminders',
        showBack: true,
        onBack: () {
          final NavigatorState nav = Navigator.of(context);
          if (nav.canPop()) {
            nav.pop();
          } else {
            AppRouter.go(context, '0003');
          }
        },
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppDimens.gutter,
          8,
          AppDimens.gutter,
          28,
        ),
        children: [
          const AppSectionHeader(
            title: 'Reminders',
            padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
          ),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: _breaks.enabled,
                  builder: (context, enabled, _) => AppListTile(
                    title: 'Enable break reminders',
                    subtitle: enabled
                        ? 'Drivana will nudge you on long drives'
                        : 'Get a nudge to stop and stretch',
                    leadingIcon: Icons.free_breakfast_rounded,
                    showChevron: false,
                    onTap: _busy ? null : () => _toggle(!enabled),
                    // Colours come from the ambient theme, per the design
                    // system's "never hardcode a control colour" rule.
                    trailing: Switch.adaptive(
                      value: enabled,
                      onChanged: _busy ? null : _toggle,
                    ),
                  ),
                ),
                const _Divider(),
                ValueListenableBuilder<int>(
                  valueListenable: _breaks.intervalMinutes,
                  builder: (context, minutes, _) => _StepperRow(
                    minutes: minutes,
                    onDecrease: minutes <=
                            BreakReminderService.minIntervalMinutes
                        ? null
                        : () =>
                            _step(-BreakReminderService.intervalStepMinutes),
                    onIncrease: minutes >=
                            BreakReminderService.maxIntervalMinutes
                        ? null
                        : () =>
                            _step(BreakReminderService.intervalStepMinutes),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const AppSectionHeader(
            title: 'Drive timer',
            padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
          ),
          _DriveTimerCard(breaks: _breaks),
          const SizedBox(height: 20),

          // Permission state — real, read back from the OS.
          ValueListenableBuilder<bool>(
            valueListenable: AppState.notificationsEnabled,
            builder: (context, granted, _) {
              if (granted) {
                return const AppBanner(
                  tone: AppBannerTone.info,
                  title: 'Alerts on',
                  message:
                      'Drivana can alert you. Reminders run while Focus Drive '
                      'is on screen — that is where the drive timer counts.',
                  icon: Icons.notifications_active_rounded,
                );
              }
              return AppBanner(
                title: 'Alerts are off',
                message:
                    'Break reminders need notification access. You can turn it '
                    'on for Drivana in iOS Settings.',
                icon: Icons.notifications_off_rounded,
                trailing: AppButton(
                  label: 'Settings',
                  variant: AppButtonVariant.gradient,
                  expanded: false,
                  height: 40,
                  onPressed: () => openAppSettings(),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          AppButton(
            label: 'Save',
            variant: AppButtonVariant.gradient,
            icon: Icons.check_rounded,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

/// The "remind me every N minutes" stepper.
class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.minutes,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int minutes;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.gutter,
        vertical: 12,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: const Icon(Icons.timelapse_rounded,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Remind me every',
                  style: (text.bodyLarge ?? const TextStyle()).copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$minutes minutes of driving',
                  style: (text.bodySmall ?? const TextStyle())
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          _StepButton(icon: Icons.remove_rounded, onTap: onDecrease),
          const SizedBox(width: 8),
          SizedBox(
            width: 34,
            child: Text(
              '$minutes',
              textAlign: TextAlign.center,
              style: (text.titleMedium ?? const TextStyle()).copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _StepButton(icon: Icons.add_rounded, onTap: onIncrease),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    return Material(
      color: enabled
          ? AppColors.primary.withValues(alpha: 0.16)
          : AppColors.textSecondary.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            icon,
            size: 18,
            color: enabled ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Live drive timer — the REAL elapsed time of a recording Focus Drive.
class _DriveTimerCard extends StatelessWidget {
  const _DriveTimerCard({required this.breaks});

  final BreakReminderService breaks;

  static String _clock(Duration d) {
    final String hh = d.inHours.toString().padLeft(2, '0');
    final String mm = (d.inMinutes % 60).toString().padLeft(2, '0');
    final String ss = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final TripRecorder recorder = TripRecorder.instance;

    return ValueListenableBuilder<bool>(
      valueListenable: recorder.recording,
      builder: (context, recording, _) {
        return AppCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    recording
                        ? Icons.timer_rounded
                        : Icons.timer_off_outlined,
                    color: recording
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    recording ? 'Driving now' : 'Not driving',
                    style: (text.labelLarge ?? const TextStyle()).copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ValueListenableBuilder<Duration>(
                valueListenable: recorder.elapsed,
                builder: (context, elapsed, _) => Text(
                  _clock(elapsed),
                  style: (text.displaySmall ?? const TextStyle()).copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              ValueListenableBuilder<Duration?>(
                valueListenable: breaks.nextBreakIn,
                builder: (context, next, _) {
                  final String message;
                  if (!recording) {
                    message =
                        'Start a Focus Drive and this counts your real driving '
                        'time.';
                  } else if (next == null) {
                    message = 'Reminders are off for this drive.';
                  } else {
                    message = 'Next break nudge in ${_clock(next)}.';
                  }
                  return Text(
                    message,
                    style: (text.bodySmall ?? const TextStyle())
                        .copyWith(color: AppColors.textSecondary),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: AppDimens.gutter,
      endIndent: AppDimens.gutter,
      color: AppColors.textSecondary.withValues(alpha: 0.12),
    );
  }
}
