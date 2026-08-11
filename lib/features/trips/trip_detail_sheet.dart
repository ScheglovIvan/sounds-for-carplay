import 'dart:math' as math;

import 'package:apple_maps_flutter/apple_maps_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:drivana/core/app_state.dart';
import 'package:drivana/core/format/units_format.dart';
import 'package:drivana/core/models/trip.dart';
import 'package:drivana/core/models/user_settings.dart';
import 'package:drivana/ui/components/components.dart';

/// Trip detail (`app_spec.json` › screens › trips › `detail_sheet`).
///
/// Opens as a modal sheet over the Trips list and shows the drive exactly as it
/// was recorded: the REAL route drawn on a native Apple Map from the stored GPS
/// fixes, the measured distance and duration, the computed score and every
/// harsh event. Nothing is padded out — a drive with no events says so.
class TripDetailSheet extends StatelessWidget {
  const TripDetailSheet({super.key, required this.trip});

  final Trip trip;

  /// Present [trip] as a modal bottom sheet.
  static Future<void> show(BuildContext context, Trip trip) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TripDetailSheet(trip: trip),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final DateFormat stamp = DateFormat('EEEE d MMMM · HH:mm');

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadii.md),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(
              AppDimens.gutter,
              10,
              AppDimens.gutter,
              28,
            ),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                stamp.format(trip.startedAt),
                style: (text.titleMedium ?? const TextStyle()).copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 220,
                child: TripRouteMap(trip: trip),
              ),
              const SizedBox(height: 16),
              _StatsGrid(trip: trip),
              const SizedBox(height: 20),
              const AppSectionHeader(
                title: 'Harsh events',
                padding: EdgeInsets.fromLTRB(4, 0, 4, 12),
              ),
              _EventList(trip: trip),
            ],
          ),
        );
      },
    );
  }
}

/// The recorded route drawn on a native Apple Map (MapKit, no API key).
///
/// The line is the trip's own stored fixes — not a generated shape. Where MapKit
/// cannot render (web preview, non-iOS), an honest note replaces it rather than
/// a fake map image (see `CAPABILITIES.md`).
class TripRouteMap extends StatelessWidget {
  const TripRouteMap({super.key, required this.trip});

  final Trip trip;

  static bool get _mapKitAvailable =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Centre + zoom that frame the whole recorded route.
  static (LatLng, double) _camera(List<TripPoint> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    for (final TripPoint p in points) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }
    final LatLng centre = LatLng(
      (minLat + maxLat) / 2,
      (minLng + maxLng) / 2,
    );

    // Longitude degrees shrink with latitude, so weight the horizontal span.
    final double latSpan = (maxLat - minLat).abs();
    final double lngSpan =
        (maxLng - minLng).abs() * math.cos(centre.latitude * math.pi / 180);
    final double span = math.max(math.max(latSpan, lngSpan), 0.0008);
    final double zoom = (math.log(360 / span) / math.ln2) - 0.6;
    return (centre, zoom.clamp(3.0, 16.5));
  }

  @override
  Widget build(BuildContext context) {
    final List<TripPoint> points = trip.points;

    if (points.isEmpty) {
      return _note(
        context,
        icon: Icons.location_off_rounded,
        title: 'No route recorded',
        message:
            'This drive was logged without usable GPS fixes, so there is no '
            'line to draw.',
      );
    }

    if (!_mapKitAvailable) {
      return _note(
        context,
        icon: Icons.map_rounded,
        title: 'Route map runs on device',
        message: 'Native Apple Maps renders your route on your iPhone.',
      );
    }

    final (LatLng centre, double zoom) = _camera(points);
    final List<LatLng> line = <LatLng>[
      for (final TripPoint p in points) LatLng(p.latitude, p.longitude),
    ];

    return ClipRRect(
      borderRadius: AppRadii.rMd,
      child: AppleMap(
        initialCameraPosition: CameraPosition(target: centre, zoom: zoom),
        zoomGesturesEnabled: true,
        scrollGesturesEnabled: true,
        polylines: <Polyline>{
          Polyline(
            polylineId: PolylineId('trip-${trip.id}'),
            points: line,
            color: AppColors.primary,
            width: 5,
          ),
        },
        annotations: <Annotation>{
          Annotation(
            annotationId: AnnotationId('start-${trip.id}'),
            position: line.first,
          ),
          if (line.length > 1)
            Annotation(
              annotationId: AnnotationId('end-${trip.id}'),
              position: line.last,
            ),
        },
      ),
    );
  }

  Widget _note(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
  }) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.rMd,
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 30),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: (text.titleSmall ?? const TextStyle()).copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: (text.bodySmall ?? const TextStyle())
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SpeedUnit>(
      valueListenable: AppState.unitSpeed,
      builder: (context, unit, _) {
        final double? avg = trip.averageSpeedKmh;
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    label: 'Distance',
                    value: UnitsFormat.distance(trip.distanceKm, unit),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Stat(
                    label: 'Duration',
                    value: formatTripDuration(trip.duration),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    label: 'Score',
                    value: '${trip.score}',
                    accent: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Stat(
                    label: 'Average speed',
                    value: avg == null
                        ? '—'
                        : '${UnitsFormat.distance(avg, unit)}/h',
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    this.accent = false,
  });

  final String label;
  final String value;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: (text.bodySmall ?? const TextStyle())
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: (text.titleLarge ?? const TextStyle()).copyWith(
              color: accent ? AppColors.primary : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventList extends StatelessWidget {
  const _EventList({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    if (trip.events.isEmpty) {
      return AppCard(
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'A smooth drive — no harsh braking or hard acceleration.',
                style: (Theme.of(context).textTheme.bodyMedium ??
                        const TextStyle())
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    final DateFormat clock = DateFormat.Hms();
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (int i = 0; i < trip.events.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: AppColors.textSecondary.withValues(alpha: 0.12),
              ),
            AppListTile(
              title: trip.events[i].kind.label,
              subtitle: trip.events[i].speedKmh == null
                  ? clock.format(trip.events[i].at)
                  : '${clock.format(trip.events[i].at)} · '
                      '${trip.events[i].speedKmh!.round()} km/h',
              leadingIcon:
                  trip.events[i].kind == DriveEventKind.harshBraking
                      ? Icons.trending_down_rounded
                      : Icons.trending_up_rounded,
              leadingColor:
                  trip.events[i].kind == DriveEventKind.harshBraking
                      ? AppColors.primaryGradientEnd
                      : AppColors.ratingStar,
              showChevron: false,
              trailing: AppBadge(
                label: trip.events[i].severityLabel.toUpperCase(),
                tone: trip.events[i].severity >= 0.66
                    ? AppBadgeTone.accent
                    : AppBadgeTone.neutral,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// `1h 12m` / `18m` / `45s` — shared by the Trips list and this sheet.
String formatTripDuration(Duration d) {
  if (d.inMinutes < 1) return '${d.inSeconds}s';
  final int hours = d.inHours;
  final int minutes = d.inMinutes % 60;
  if (hours > 0) return '${hours}h ${minutes}m';
  return '${minutes}m';
}
