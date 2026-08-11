import 'package:flutter_test/flutter_test.dart';

import 'package:drivana/core/models/trip.dart';

/// The Drive Score / Trips screens show only what was actually recorded, so the
/// scoring maths and the JSON round-trip that persists a drive are pinned here.
void main() {
  Trip tripWith(List<DriveEvent> events, {int minutes = 20}) {
    final DateTime start = DateTime(2026, 8, 10, 9);
    return Trip(
      id: '${start.millisecondsSinceEpoch}',
      startedAt: start,
      endedAt: start.add(Duration(minutes: minutes)),
      distanceMeters: 12000,
      points: const <TripPoint>[TripPoint(51.5, -0.12), TripPoint(51.51, -0.13)],
      events: events,
    );
  }

  test('a drive with no harsh events keeps the full score', () {
    final Trip trip = tripWith(const <DriveEvent>[]);
    expect(trip.score, 100);
    expect(trip.isSmooth, isTrue);
  });

  test('each harsh event costs 5 plus its severity, and severity is capped', () {
    final DateTime at = DateTime(2026, 8, 10, 9, 5);
    final Trip trip = tripWith(<DriveEvent>[
      // severity 0.125 -> 5 + 1 = 6
      DriveEvent(kind: DriveEventKind.harshBraking, at: at, magnitude: 3.0),
      // severity 0.75  -> 5 + 6 = 11
      DriveEvent(
        kind: DriveEventKind.hardAcceleration,
        at: at,
        magnitude: 5.5,
      ),
    ]);

    expect(trip.score, 83);
    expect(trip.isSmooth, isFalse);
    expect(trip.countOf(DriveEventKind.harshBraking), 1);
    expect(trip.countOf(DriveEventKind.hardAcceleration), 1);
  });

  test('stats fold trips without inventing a score for an empty period', () {
    expect(TripStats.from(const <Trip>[]).score, isNull);
    expect(TripStats.from(const <Trip>[]).isEmpty, isTrue);

    final TripStats stats = TripStats.from(<Trip>[tripWith(const [])]);
    expect(stats.tripCount, 1);
    expect(stats.score, 100);
    expect(stats.smoothTrips, 1);
    expect(stats.distanceKm, 12);
  });

  test('a long route is down-sampled but keeps its first and last fix', () {
    final List<TripPoint> points = <TripPoint>[
      for (int i = 0; i < 1000; i++) TripPoint(51.5 + i / 10000, -0.12),
    ];

    final List<TripPoint> reduced = Trip.downsample(points);

    expect(reduced.length, lessThanOrEqualTo(301));
    expect(reduced.first.latitude, points.first.latitude);
    expect(reduced.last.latitude, points.last.latitude);
  });

  test('a recorded drive survives the JSON round-trip it is stored with', () {
    final Trip original = tripWith(<DriveEvent>[
      DriveEvent(
        kind: DriveEventKind.harshBraking,
        at: DateTime(2026, 8, 10, 9, 7),
        magnitude: 4.2,
        speedKmh: 63,
      ),
    ]);

    final Trip? restored = Trip.fromJson(original.toJson());

    expect(restored, isNotNull);
    expect(restored!.id, original.id);
    expect(restored.startedAt, original.startedAt);
    expect(restored.distanceMeters, original.distanceMeters);
    expect(restored.points.length, original.points.length);
    expect(restored.points.first.latitude, closeTo(51.5, 0.000001));
    expect(restored.events.single.kind, DriveEventKind.harshBraking);
    expect(restored.events.single.speedKmh, 63);
    expect(restored.score, original.score);
  });
}
