import 'package:flutter/foundation.dart';

import '../models/trip.dart';
import 'preferences_store.dart';

/// On-device history of recorded drives.
///
/// Trips are produced by [TripRecorder] from REAL GPS during Focus Drive and
/// stored locally through [PreferencesStore] — there is no seeded/demo history,
/// so a fresh install genuinely shows an empty Trips tab until the user drives.
///
/// The list is kept newest-first and capped at [maxTrips] so storage stays
/// bounded on a long-lived install.
class TripStore {
  TripStore._();

  static final TripStore instance = TripStore._();

  /// How many drives we keep on device.
  static const int maxTrips = 50;

  /// How many of them a FREE user can see (full history is a PRO feature —
  /// `app_spec.json` › screens › trips).
  static const int freeVisibleTrips = 3;

  final PreferencesStore _store = PreferencesStore.instance;

  /// All stored trips, newest first.
  final ValueNotifier<List<Trip>> trips = ValueNotifier<List<Trip>>(
    const <Trip>[],
  );

  bool _loaded = false;

  /// Hydrate from disk. Cheap and idempotent — the underlying prefs instance is
  /// already warm by the time [AppState.load] has run.
  Future<void> load() async {
    if (_loaded) return;
    await _store.ensureLoaded();
    final Map<String, dynamic>? envelope = _store.getJson(PreferencesStore.kTrips);
    final List<dynamic> raw =
        (envelope?['items'] as List<dynamic>?) ?? const <dynamic>[];
    final List<Trip> parsed = <Trip>[];
    for (final dynamic item in raw) {
      if (item is! Map<String, dynamic>) continue;
      final Trip? trip = Trip.fromJson(item);
      if (trip != null) parsed.add(trip);
    }
    parsed.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    trips.value = List<Trip>.unmodifiable(parsed);
    _loaded = true;
  }

  /// Append a freshly recorded drive and persist the history.
  Future<void> add(Trip trip) async {
    final List<Trip> next = <Trip>[trip, ...trips.value];
    if (next.length > maxTrips) next.removeRange(maxTrips, next.length);
    trips.value = List<Trip>.unmodifiable(next);
    await _persist();
  }

  /// Forget every recorded drive (Settings › Break Reminders and the Drive
  /// Score screen both offer this so the user stays in control of their data).
  Future<void> clear() async {
    trips.value = const <Trip>[];
    await _persist();
  }

  Future<void> _persist() async {
    await _store.setJson(PreferencesStore.kTrips, <String, dynamic>{
      'items': <Map<String, dynamic>>[
        for (final Trip t in trips.value) t.toJson(),
      ],
    });
  }

  // ── Queries ───────────────────────────────────────────────────────────────

  /// The trips a user with this entitlement may browse. Free users see the most
  /// recent [freeVisibleTrips]; PRO sees everything.
  List<Trip> visible({required bool isPro}) {
    final List<Trip> all = trips.value;
    if (isPro || all.length <= freeVisibleTrips) return all;
    return all.sublist(0, freeVisibleTrips);
  }

  /// How many trips are hidden behind the PRO gate right now.
  int lockedCount({required bool isPro}) {
    if (isPro) return 0;
    final int extra = trips.value.length - freeVisibleTrips;
    return extra > 0 ? extra : 0;
  }

  /// Trips that started within the last 7 days (the free Drive Score window).
  List<Trip> thisWeek() {
    final DateTime cutoff = _startOfDay(DateTime.now())
        .subtract(const Duration(days: 6));
    return trips.value
        .where((t) => !t.startedAt.isBefore(cutoff))
        .toList(growable: false);
  }

  /// Per-day score for the last 7 days, oldest first. `null` for a day with no
  /// recorded drive — the chart leaves those columns empty rather than
  /// inventing a value.
  List<({DateTime day, int? score})> weeklyTrend() {
    final DateTime today = _startOfDay(DateTime.now());
    final List<({DateTime day, int? score})> out =
        <({DateTime day, int? score})>[];
    for (int i = 6; i >= 0; i--) {
      final DateTime day = today.subtract(Duration(days: i));
      final List<Trip> onDay = trips.value
          .where((t) => _startOfDay(t.startedAt) == day)
          .toList(growable: false);
      out.add((day: day, score: TripStats.from(onDay).score));
    }
    return out;
  }

  /// The most recent harsh events across all trips, newest first.
  List<DriveEvent> recentEvents({int limit = 12}) {
    final List<DriveEvent> all = <DriveEvent>[
      for (final Trip t in trips.value) ...t.events,
    ]..sort((a, b) => b.at.compareTo(a.at));
    return all.length <= limit ? all : all.sublist(0, limit);
  }

  static DateTime _startOfDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
