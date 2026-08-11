import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:drivana/core/app_state.dart';
import 'package:drivana/core/format/units_format.dart';
import 'package:drivana/core/models/user_settings.dart';
import 'package:drivana/core/services/trip_recorder.dart';
import 'package:drivana/ui/theme/app_theme.dart';

/// The status strip along the top of the Focus Drive board.
///
/// Every value is REAL and live — nothing here is hardcoded:
///   * clock/date  → [DateTime.now] on a one-second [Timer], formatted with intl
///   * battery     → level + charging state via `battery_plus`
///   * network     → Wi‑Fi / cellular / offline via `connectivity_plus`
///   * trip        → distance + elapsed time of the drive [TripRecorder] is
///                   recording right now from the live GPS stream
class DriveStatusBar extends StatefulWidget {
  const DriveStatusBar({super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  State<DriveStatusBar> createState() => _DriveStatusBarState();
}

class _DriveStatusBarState extends State<DriveStatusBar> {
  final Battery _battery = Battery();
  final Connectivity _connectivity = Connectivity();

  Timer? _clock;
  StreamSubscription<BatteryState>? _batterySub;
  StreamSubscription<List<ConnectivityResult>>? _netSub;

  DateTime _now = DateTime.now();
  int _tick = 0;

  int? _batteryLevel;
  BatteryState _batteryState = BatteryState.unknown;
  List<ConnectivityResult> _network = const <ConnectivityResult>[
    ConnectivityResult.none,
  ];

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _now = DateTime.now();
        _tick++;
      });
      // Battery level does not stream, so refresh it periodically.
      if (_tick % 15 == 0) _refreshBattery();
    });
    _initBattery();
    _initNetwork();
  }

  Future<void> _initBattery() async {
    if (kIsWeb) return;
    await _refreshBattery();
    try {
      _batterySub = _battery.onBatteryStateChanged.listen((state) {
        if (!mounted) return;
        setState(() => _batteryState = state);
        _refreshBattery();
      });
    } catch (_) {
      // Platform without battery support — leave as unknown.
    }
  }

  Future<void> _refreshBattery() async {
    if (kIsWeb) return;
    try {
      final int level = await _battery.batteryLevel;
      final BatteryState state = await _battery.batteryState;
      if (!mounted) return;
      setState(() {
        _batteryLevel = level;
        _batteryState = state;
      });
    } catch (_) {
      // ignore
    }
  }

  Future<void> _initNetwork() async {
    try {
      final List<ConnectivityResult> initial =
          await _connectivity.checkConnectivity();
      if (mounted) setState(() => _network = initial);
    } catch (_) {
      // ignore
    }
    try {
      _netSub = _connectivity.onConnectivityChanged.listen((result) {
        if (mounted) setState(() => _network = result);
      });
    } catch (_) {
      // ignore
    }
  }

  @override
  void dispose() {
    _clock?.cancel();
    _batterySub?.cancel();
    _netSub?.cancel();
    super.dispose();
  }

  bool get _charging =>
      _batteryState == BatteryState.charging ||
      _batteryState == BatteryState.full;

  IconData get _networkIcon {
    if (_network.contains(ConnectivityResult.wifi)) {
      return Icons.wifi_rounded;
    }
    if (_network.contains(ConnectivityResult.mobile)) {
      return Icons.signal_cellular_alt_rounded;
    }
    if (_network.contains(ConnectivityResult.ethernet) ||
        _network.contains(ConnectivityResult.vpn)) {
      return Icons.lan_rounded;
    }
    return Icons.signal_wifi_off_rounded;
  }

  IconData get _batteryIcon {
    if (_charging) return Icons.battery_charging_full_rounded;
    final int level = _batteryLevel ?? 0;
    if (level >= 95) return Icons.battery_full_rounded;
    if (level >= 80) return Icons.battery_6_bar_rounded;
    if (level >= 60) return Icons.battery_5_bar_rounded;
    if (level >= 45) return Icons.battery_4_bar_rounded;
    if (level >= 30) return Icons.battery_3_bar_rounded;
    if (level >= 15) return Icons.battery_2_bar_rounded;
    if (level > 0) return Icons.battery_1_bar_rounded;
    return Icons.battery_0_bar_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle mono = (Theme.of(context).textTheme.titleMedium ??
            const TextStyle())
        .copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700);
    final TextStyle sub =
        (Theme.of(context).textTheme.bodySmall ?? const TextStyle())
            .copyWith(color: AppColors.textSecondary);

    final String time = DateFormat.Hm().format(_now);
    final String date = DateFormat('EEEE, MMMM d, y').format(_now);
    final Color batteryColor = !_charging && (_batteryLevel ?? 100) <= 15
        ? AppColors.primaryGradientEnd
        : AppColors.textPrimary;

    // Fixed-height strip so the Close button can be pinned to the TOP-RIGHT
    // corner (like the original) regardless of the readouts' intrinsic height.
    // The readout row reserves space on the right so nothing sits under the
    // button, and the Focus Drive body is already inside a SafeArea + fixed
    // 14pt inset, keeping the button correctly placed on every device size.
    const double closeSlot = 34.0 + 12.0; // button + gap

    return SizedBox(
      height: 40,
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(
                right: widget.onClose != null ? closeSlot : 0.0,
              ),
              child: Row(
                children: [
                  Text(time, style: mono),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      date,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: sub,
                    ),
                  ),
                  const Spacer(),
                  const _TripReadout(),
                  Icon(_networkIcon, size: 18, color: AppColors.textPrimary),
                  const SizedBox(width: 12),
                  Icon(_batteryIcon, size: 20, color: batteryColor),
                  const SizedBox(width: 4),
                  Text(
                    _batteryLevel == null ? '--' : '$_batteryLevel%',
                    style: sub.copyWith(color: batteryColor),
                  ),
                ],
              ),
            ),
          ),
          if (widget.onClose != null)
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              child: Center(child: _CloseButton(onTap: widget.onClose!)),
            ),
        ],
      ),
    );
  }
}

/// Live distance + elapsed time for the drive currently being recorded.
///
/// Bound straight to [TripRecorder]; when nothing is recording (location not
/// granted yet) it renders nothing at all rather than a frozen `0.0 km`.
class _TripReadout extends StatelessWidget {
  const _TripReadout();

  static String _clock(Duration d) {
    final String mm = (d.inMinutes % 60).toString().padLeft(2, '0');
    final String ss = (d.inSeconds % 60).toString().padLeft(2, '0');
    if (d.inHours > 0) return '${d.inHours}:$mm:$ss';
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final TripRecorder recorder = TripRecorder.instance;
    final TextStyle style =
        (Theme.of(context).textTheme.bodySmall ?? const TextStyle())
            .copyWith(color: AppColors.textSecondary);

    return ValueListenableBuilder<bool>(
      valueListenable: recorder.recording,
      builder: (context, recording, _) {
        if (!recording) return const SizedBox.shrink();
        return ValueListenableBuilder<double>(
          valueListenable: recorder.distanceMeters,
          builder: (context, meters, _) => ValueListenableBuilder<Duration>(
            valueListenable: recorder.elapsed,
            builder: (context, elapsed, _) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.route_rounded,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 5),
                  ValueListenableBuilder<SpeedUnit>(
                    valueListenable: AppState.unitSpeed,
                    builder: (context, unit, _) => Text(
                      '${UnitsFormat.distance(meters / 1000, unit)} · '
                      '${_clock(elapsed)}',
                      style: style,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(Icons.close_rounded,
              color: AppColors.textPrimary, size: 20),
        ),
      ),
    );
  }
}
