import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/trip.dart';
import 'break_reminder_service.dart';
import 'location_service.dart';
import 'trip_store.dart';

/// Records a real drive while the Focus Drive board is open.
///
/// Everything it produces comes from the device, never from a script:
///   * the route and its distance are summed from consecutive CoreLocation
///     fixes ([LocationService.positionStream] → `Geolocator.distanceBetween`);
///   * live speed is the fix's own `speed` (m/s) reported by CoreLocation;
///   * harsh braking / hard acceleration are detected from the longitudinal
///     acceleration BETWEEN two real fixes (Δspeed / Δt).
///
/// On stop the drive is handed to [TripStore], which is what makes the Trips
/// and Drive Score screens show genuine history.
///
/// LIMIT: Drivana ships no Always-on background location entitlement, so
/// recording runs while Focus Drive is on screen (the app's driving board).
/// Detection therefore uses CoreLocation speed deltas rather than a
/// higher-rate CoreMotion accelerometer feed — see `CAPABILITIES.md`.
class TripRecorder {
  TripRecorder._();

  static final TripRecorder instance = TripRecorder._();

  // ── Harsh-event detection thresholds (m/s²) ────────────────────────────────
  /// Deceleration at or beyond this counts as harsh braking (≈ 0.3 g).
  static const double _brakingThreshold = -3.0;

  /// Acceleration at or beyond this counts as a hard launch.
  static const double _accelerationThreshold = 2.6;

  /// Ignore samples spaced outside this window — a very short gap amplifies GPS
  /// speed noise, a very long one is not a single manoeuvre any more.
  static const double _minSampleSeconds = 0.7;
  static const double _maxSampleSeconds = 8.0;

  /// A manoeuvre must involve real road speed (≈ 18 km/h) at one end, so
  /// creeping in a car park never scores against the driver.
  static const double _minRelevantSpeedMps = 5.0;

  /// One event of a kind per this window, so a single long stop cannot log ten.
  static const Duration _eventCooldown = Duration(seconds: 6);

  final LocationService _location = LocationService.instance;

  // ── Live, observable drive state ──────────────────────────────────────────
  final ValueNotifier<bool> recording = ValueNotifier<bool>(false);
  final ValueNotifier<Duration> elapsed =
      ValueNotifier<Duration>(Duration.zero);

  /// Distance covered so far, in metres.
  final ValueNotifier<double> distanceMeters = ValueNotifier<double>(0);

  /// The latest real speed reported by CoreLocation, in m/s. Null until a fix
  /// with a valid speed arrives.
  final ValueNotifier<double?> speedMps = ValueNotifier<double?>(null);

  /// Harsh events detected in the current drive.
  final ValueNotifier<int> eventCount = ValueNotifier<int>(0);

  StreamSubscription<Position>? _sub;
  Timer? _ticker;

  DateTime? _startedAt;
  final List<TripPoint> _points = <TripPoint>[];
  final List<DriveEvent> _events = <DriveEvent>[];

  Position? _lastPosition;
  double? _lastSpeed;
  DateTime? _lastSampleAt;
  final Map<DriveEventKind, DateTime> _lastEventAt =
      <DriveEventKind, DateTime>{};

  /// Begin recording. Requires (and asks for) real location permission —
  /// returns false when it is not granted, in which case nothing is recorded
  /// and no fake trip is produced.
  Future<bool> start() async {
    if (recording.value) return true;
    if (kIsWeb) return false;

    final bool granted = await _location.ensurePermission();
    if (!granted) return false;

    _reset();
    _startedAt = DateTime.now();
    recording.value = true;
    BreakReminderService.instance.resetDrive();

    // Seed the route from whatever fix the OS already holds so a short drive
    // still draws a line.
    final Position? seed = await _location.lastKnownPosition();
    if (seed != null && recording.value) {
      _lastPosition = seed;
      _points.add(TripPoint(seed.latitude, seed.longitude));
    }

    _sub = _location
        .positionStream(distanceFilterMeters: 8)
        .listen(_onPosition, onError: (Object _) {});

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final DateTime? started = _startedAt;
      if (started == null) return;
      elapsed.value = DateTime.now().difference(started);
      BreakReminderService.instance.onDriveTick(elapsed.value);
    });

    return true;
  }

  /// Stop recording and persist the drive.
  ///
  /// Trips shorter than 60 seconds or 150 m are discarded rather than saved —
  /// opening and closing the board should not litter the history with a
  /// zero-distance "drive".
  Future<Trip?> stop() async {
    if (!recording.value) return null;

    await _sub?.cancel();
    _sub = null;
    _ticker?.cancel();
    _ticker = null;

    final DateTime? started = _startedAt;
    final DateTime ended = DateTime.now();
    recording.value = false;
    BreakReminderService.instance.resetDrive();

    if (started == null) {
      _reset();
      return null;
    }

    final Duration duration = ended.difference(started);
    final double meters = distanceMeters.value;
    if (duration.inSeconds < 60 || meters < 150) {
      _reset();
      return null;
    }

    final Trip trip = Trip(
      id: '${started.millisecondsSinceEpoch}',
      startedAt: started,
      endedAt: ended,
      distanceMeters: meters,
      points: Trip.downsample(_points),
      events: List<DriveEvent>.unmodifiable(_events),
    );

    await TripStore.instance.add(trip);
    _reset();
    return trip;
  }

  void _reset() {
    _startedAt = null;
    _points.clear();
    _events.clear();
    _lastPosition = null;
    _lastSpeed = null;
    _lastSampleAt = null;
    _lastEventAt.clear();
    elapsed.value = Duration.zero;
    distanceMeters.value = 0;
    speedMps.value = null;
    eventCount.value = 0;
  }

  void _onPosition(Position position) {
    if (!recording.value) return;

    // Distance: real ground distance between this fix and the previous one.
    final Position? previous = _lastPosition;
    if (previous != null) {
      final double step = Geolocator.distanceBetween(
        previous.latitude,
        previous.longitude,
        position.latitude,
        position.longitude,
      );
      // Discard implausible jumps (a re-acquired fix after a tunnel) so the
      // total stays honest.
      if (step.isFinite && step > 0 && step < 2000) {
        distanceMeters.value = distanceMeters.value + step;
      }
    }
    _lastPosition = position;
    _points.add(TripPoint(position.latitude, position.longitude));

    // Speed: CoreLocation reports a negative value when it has no valid speed.
    final double? speed =
        (position.speed.isFinite && position.speed >= 0) ? position.speed : null;
    speedMps.value = speed;
    if (speed == null) {
      _lastSpeed = null;
      _lastSampleAt = null;
      return;
    }

    _detectEvent(speed);
    _lastSpeed = speed;
    _lastSampleAt = DateTime.now();
  }

  /// Longitudinal acceleration between the last two valid speed samples.
  void _detectEvent(double speed) {
    final double? previousSpeed = _lastSpeed;
    final DateTime? previousAt = _lastSampleAt;
    if (previousSpeed == null || previousAt == null) return;

    final DateTime now = DateTime.now();
    final double dt = now.difference(previousAt).inMilliseconds / 1000.0;
    if (dt < _minSampleSeconds || dt > _maxSampleSeconds) return;

    final double acceleration = (speed - previousSpeed) / dt;
    if (!acceleration.isFinite) return;

    DriveEventKind? kind;
    if (acceleration <= _brakingThreshold &&
        previousSpeed >= _minRelevantSpeedMps) {
      kind = DriveEventKind.harshBraking;
    } else if (acceleration >= _accelerationThreshold &&
        speed >= _minRelevantSpeedMps) {
      kind = DriveEventKind.hardAcceleration;
    }
    if (kind == null) return;

    final DateTime? last = _lastEventAt[kind];
    if (last != null && now.difference(last) < _eventCooldown) return;
    _lastEventAt[kind] = now;

    _events.add(
      DriveEvent(
        kind: kind,
        at: now,
        magnitude: acceleration.abs(),
        speedKmh: speed * 3.6,
      ),
    );
    eventCount.value = _events.length;
  }
}
