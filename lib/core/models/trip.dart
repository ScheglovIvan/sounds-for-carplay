import 'dart:math' as math;

/// The two driving events Drivana scores against.
///
/// Both are derived from REAL device motion: the longitudinal acceleration
/// between two consecutive CoreLocation fixes (see `TripRecorder`). Nothing here
/// is simulated — a trip with no harsh moments genuinely records none.
enum DriveEventKind {
  harshBraking('Harsh braking'),
  hardAcceleration('Hard acceleration');

  const DriveEventKind(this.label);

  final String label;

  static DriveEventKind fromKey(String? key) => key == 'accel'
      ? DriveEventKind.hardAcceleration
      : DriveEventKind.harshBraking;

  String get key =>
      this == DriveEventKind.hardAcceleration ? 'accel' : 'brake';
}

/// A single harsh moment inside a trip.
class DriveEvent {
  const DriveEvent({
    required this.kind,
    required this.at,
    required this.magnitude,
    this.speedKmh,
  });

  final DriveEventKind kind;
  final DateTime at;

  /// Absolute longitudinal acceleration in m/s² that triggered the event.
  final double magnitude;

  /// Speed at the moment the event was detected, in km/h.
  final double? speedKmh;

  /// 0..1 — how far past the detection threshold this event went. Drives both
  /// the score penalty and the severity wording in the UI.
  double get severity => ((magnitude - 2.5) / 4.0).clamp(0.0, 1.0);

  String get severityLabel {
    if (severity >= 0.66) return 'Severe';
    if (severity >= 0.33) return 'Moderate';
    return 'Mild';
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'k': kind.key,
        't': at.millisecondsSinceEpoch,
        'm': magnitude,
        if (speedKmh != null) 's': speedKmh,
      };

  static DriveEvent fromJson(Map<String, dynamic> json) => DriveEvent(
        kind: DriveEventKind.fromKey(json['k'] as String?),
        at: DateTime.fromMillisecondsSinceEpoch((json['t'] as num?)?.toInt() ?? 0),
        magnitude: (json['m'] as num?)?.toDouble() ?? 0,
        speedKmh: (json['s'] as num?)?.toDouble(),
      );
}

/// One recorded GPS fix along the route, kept for the trip-detail map.
class TripPoint {
  const TripPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  List<double> toJson() => <double>[latitude, longitude];

  static TripPoint? fromJson(dynamic json) {
    if (json is List && json.length >= 2) {
      final double? lat = (json[0] as num?)?.toDouble();
      final double? lng = (json[1] as num?)?.toDouble();
      if (lat != null && lng != null) return TripPoint(lat, lng);
    }
    return null;
  }
}

/// A completed drive, recorded from real GPS during Focus Drive.
class Trip {
  const Trip({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.distanceMeters,
    required this.points,
    required this.events,
  });

  /// Millisecond start timestamp as a string — unique per recording.
  final String id;
  final DateTime startedAt;
  final DateTime endedAt;

  /// Ground distance covered, summed from consecutive real fixes.
  final double distanceMeters;

  /// Down-sampled route for the detail map (empty when location never produced
  /// a fix, e.g. permission denied mid-drive).
  final List<TripPoint> points;
  final List<DriveEvent> events;

  Duration get duration {
    final Duration d = endedAt.difference(startedAt);
    return d.isNegative ? Duration.zero : d;
  }

  double get distanceKm => distanceMeters / 1000.0;

  /// Average speed in km/h over the whole trip, or null for a trip too short to
  /// mean anything.
  double? get averageSpeedKmh {
    final int seconds = duration.inSeconds;
    if (seconds < 30 || distanceMeters <= 0) return null;
    return distanceMeters / seconds * 3.6;
  }

  int countOf(DriveEventKind kind) =>
      events.where((e) => e.kind == kind).length;

  /// 0-100 safety score for this trip.
  ///
  /// Starts at 100 and deducts per harsh event, weighted by how far past the
  /// detection threshold it went (a mild event costs ~5, a severe one ~13).
  /// A drive with no harsh moments keeps the full 100 — the score is only ever
  /// computed from what was actually recorded.
  int get score {
    if (events.isEmpty) return 100;
    double penalty = 0;
    for (final DriveEvent e in events) {
      penalty += 5 + e.severity * 8;
    }
    return (100 - penalty).clamp(0, 100).round();
  }

  /// True when this drive produced no harsh events at all.
  bool get isSmooth => events.isEmpty;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'start': startedAt.millisecondsSinceEpoch,
        'end': endedAt.millisecondsSinceEpoch,
        'distance': distanceMeters,
        'points': <List<double>>[for (final TripPoint p in points) p.toJson()],
        'events': <Map<String, dynamic>>[
          for (final DriveEvent e in events) e.toJson(),
        ],
      };

  static Trip? fromJson(Map<String, dynamic> json) {
    final int? start = (json['start'] as num?)?.toInt();
    final int? end = (json['end'] as num?)?.toInt();
    if (start == null || end == null) return null;

    final List<TripPoint> points = <TripPoint>[];
    for (final dynamic raw
        in (json['points'] as List<dynamic>? ?? const <dynamic>[])) {
      final TripPoint? point = TripPoint.fromJson(raw);
      if (point != null) points.add(point);
    }

    final List<DriveEvent> events = <DriveEvent>[];
    for (final dynamic raw
        in (json['events'] as List<dynamic>? ?? const <dynamic>[])) {
      if (raw is Map<String, dynamic>) events.add(DriveEvent.fromJson(raw));
    }

    return Trip(
      id: json['id'] as String? ?? '$start',
      startedAt: DateTime.fromMillisecondsSinceEpoch(start),
      endedAt: DateTime.fromMillisecondsSinceEpoch(end),
      distanceMeters: (json['distance'] as num?)?.toDouble() ?? 0,
      points: points,
      events: events,
    );
  }

  /// Down-sample [points] to at most [max] entries, always keeping the first and
  /// last fix. Keeps a long drive's stored route inside a sane size while the
  /// drawn line still traces where the user actually went.
  static List<TripPoint> downsample(List<TripPoint> points, {int max = 300}) {
    if (points.length <= max) return List<TripPoint>.from(points);
    final int step = (points.length / max).ceil();
    final List<TripPoint> out = <TripPoint>[];
    for (int i = 0; i < points.length; i += step) {
      out.add(points[i]);
    }
    if (out.last != points.last) out.add(points.last);
    return out;
  }
}

/// Aggregate stats over a set of trips — the numbers the Drive Score and Trips
/// screens display.
class TripStats {
  const TripStats({
    required this.tripCount,
    required this.distanceMeters,
    required this.duration,
    required this.harshBraking,
    required this.hardAcceleration,
    required this.smoothTrips,
    required this.score,
  });

  final int tripCount;
  final double distanceMeters;
  final Duration duration;
  final int harshBraking;
  final int hardAcceleration;
  final int smoothTrips;

  /// Distance-weighted average of the per-trip scores, or null with no trips.
  final int? score;

  double get distanceKm => distanceMeters / 1000.0;

  bool get isEmpty => tripCount == 0;

  static const TripStats empty = TripStats(
    tripCount: 0,
    distanceMeters: 0,
    duration: Duration.zero,
    harshBraking: 0,
    hardAcceleration: 0,
    smoothTrips: 0,
    score: null,
  );

  /// Fold [trips] into one summary.
  ///
  /// The headline score is weighted by trip length so a 40-minute motorway run
  /// counts for more than a two-minute hop to the shops.
  factory TripStats.from(Iterable<Trip> trips) {
    if (trips.isEmpty) return TripStats.empty;

    int count = 0;
    double meters = 0;
    int seconds = 0;
    int braking = 0;
    int accel = 0;
    int smooth = 0;
    double weightedScore = 0;
    double weight = 0;

    for (final Trip t in trips) {
      count++;
      meters += t.distanceMeters;
      seconds += t.duration.inSeconds;
      braking += t.countOf(DriveEventKind.harshBraking);
      accel += t.countOf(DriveEventKind.hardAcceleration);
      if (t.isSmooth) smooth++;
      // Minimum weight of 1 so a very short trip still counts a little.
      final double w = math.max(1.0, t.duration.inMinutes.toDouble());
      weightedScore += t.score * w;
      weight += w;
    }

    return TripStats(
      tripCount: count,
      distanceMeters: meters,
      duration: Duration(seconds: seconds),
      harshBraking: braking,
      hardAcceleration: accel,
      smoothTrips: smooth,
      score: weight <= 0 ? null : (weightedScore / weight).round(),
    );
  }
}
