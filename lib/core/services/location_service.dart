import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Real location access for the Focus Drive map.
///
/// Uses [permission_handler] to trigger the ACTUAL iOS "Allow While Using"
/// dialog (backed by `NSLocationWhenInUseUsageDescription` in
/// `ios_permissions.json`) and [geolocator] to read the device's real GPS fix.
/// No mock coordinates — a denied/unavailable fix simply resolves to `null`.
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  /// True once we hold a usable When-In-Use (or Always) grant.
  final ValueNotifier<bool> granted = ValueNotifier<bool>(false);

  /// Request location access through the real iOS system dialog.
  ///
  /// Uses geolocator's native permission flow, which presents the actual iOS
  /// "Allow While Using" prompt backed by `NSLocationWhenInUseUsageDescription`
  /// (kept in sync in `ios_permissions.json`). Returns whether we can now read
  /// the user's position. Safe on web/desktop (returns false without throwing).
  Future<bool> ensurePermission() async {
    if (kIsWeb) return false;
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      final bool ok = perm == LocationPermission.whileInUse ||
          perm == LocationPermission.always;
      granted.value = ok;
      return ok;
    } catch (_) {
      return false;
    }
  }

  /// The last position the OS already had cached, or null when there is none.
  ///
  /// Cheap and (unlike a fresh fix) effectively instant, so the map can paint
  /// straight away while a live fix is still being acquired.
  Future<Position?> lastKnownPosition() async {
    if (kIsWeb) return null;
    try {
      return await Geolocator.getLastKnownPosition()
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      return null;
    }
  }

  /// A FRESH fix, or null when one cannot be obtained in [timeLimit].
  ///
  /// A device that cannot see satellites (indoors, a car park, no SIM, location
  /// services off) would otherwise leave `getCurrentPosition()` pending
  /// forever, which used to hang Focus Drive on a spinner. The hard
  /// [timeLimit] makes that impossible: on timeout we fall back to the OS's
  /// cached fix, and failing that resolve to null so the caller can show a
  /// retry state.
  Future<Position?> currentPosition({
    Duration timeLimit = const Duration(seconds: 10),
  }) async {
    if (kIsWeb) return null;
    try {
      return await Geolocator.getCurrentPosition(timeLimit: timeLimit)
          // Belt and braces: if the platform channel itself never answers, the
          // native timeLimit can't fire either.
          .timeout(timeLimit + const Duration(seconds: 2));
    } on TimeoutException {
      return lastKnownPosition();
    } catch (_) {
      return lastKnownPosition();
    }
  }

  /// A live stream of real GPS fixes for the follow-map.
  ///
  /// Backed by geolocator's [Geolocator.getPositionStream]; each new fix lets the
  /// map re-centre and follow the user as they move. Emits nothing on
  /// web/unsupported platforms (an empty stream) so callers degrade gracefully.
  Stream<Position> positionStream({int distanceFilterMeters = 5}) {
    if (kIsWeb) return const Stream<Position>.empty();
    try {
      return Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: distanceFilterMeters,
        ),
      );
    } catch (_) {
      return const Stream<Position>.empty();
    }
  }
}
