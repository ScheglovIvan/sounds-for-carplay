import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:drivana/core/app_state.dart';
import 'package:drivana/core/format/units_format.dart';
import 'package:drivana/core/models/trip.dart';
import 'package:drivana/core/models/user_settings.dart';
import 'package:drivana/core/router/app_router.dart';
import 'package:drivana/core/services/purchase_flow.dart';
import 'package:drivana/core/services/trip_store.dart';
import 'package:drivana/ui/components/components.dart';

import 'trip_detail_sheet.dart';

/// The Trips tab (app_spec id "trips", route `/trips`).
///
/// Real history: every row is a drive [TripRecorder] captured from GPS during a
/// Focus Drive and [TripStore] persisted. There is no seeded/demo data, so a
/// fresh install shows the empty state until the user actually drives.
///
/// Free users see the most recent [TripStore.freeVisibleTrips] drives; the full
/// history is PRO (`app_spec.json` › screens › trips).
class Screen_trips extends StatelessWidget {
  const Screen_trips({super.key});

  @override
  Widget build(BuildContext context) {
    final TripStore store = TripStore.instance;

    return AppScaffold(
      topBar: AppTopBar(
        title: 'Trips',
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Drive Score',
            icon: const Icon(Icons.speed_rounded),
            color: AppColors.textPrimary,
            onPressed: () => AppRouter.go(context, 'safety_score'),
          ),
        ],
      ),
      bottomBar: const AppMainTabBar(current: AppMainTab.trips),
      body: ValueListenableBuilder<List<Trip>>(
        valueListenable: store.trips,
        builder: (context, trips, _) {
          if (trips.isEmpty) {
            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppDimens.gutter),
              child: AppEmptyState(
                icon: Icons.route_rounded,
                title: 'No trips yet',
                message:
                    'Your drives will be listed here with their distance, '
                    'duration and score. Start a Focus Drive to record your '
                    'first one.',
                actionLabel: 'Go to Focus Drive',
                onAction: () => Navigator.of(context).pushNamedAndRemoveUntil(
                  AppMainTab.drive.route,
                  (route) => false,
                ),
              ),
            );
          }

          return ValueListenableBuilder<bool>(
            valueListenable: AppState.isPro,
            builder: (context, isPro, _) {
              final List<Trip> visible = store.visible(isPro: isPro);
              final int locked = store.lockedCount(isPro: isPro);
              final TripStats week = TripStats.from(store.thisWeek());

              return ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppDimens.gutter,
                  8,
                  AppDimens.gutter,
                  28,
                ),
                children: [
                  _WeekSummary(stats: week),
                  const SizedBox(height: 20),
                  const AppSectionHeader(
                    title: 'Your drives',
                    padding: EdgeInsets.fromLTRB(4, 0, 4, 12),
                  ),
                  for (final Trip trip in visible) ...[
                    _TripRow(
                      trip: trip,
                      onTap: () => TripDetailSheet.show(context, trip),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (locked > 0) ...[
                    const SizedBox(height: 2),
                    AppBanner(
                      title: 'Full history is PRO',
                      message:
                          '$locked older ${locked == 1 ? 'drive is' : 'drives are'} '
                          'saved on this iPhone. Unlock PRO to browse them all.',
                      icon: Icons.lock_rounded,
                      trailing: AppButton(
                        label: 'Unlock',
                        variant: AppButtonVariant.gradient,
                        expanded: false,
                        height: 40,
                        onPressed: () => PurchaseFlow.openPaywall(context),
                      ),
                      onTap: () => PurchaseFlow.openPaywall(context),
                    ),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// "This week" totals across every recorded drive in the last 7 days.
class _WeekSummary extends StatelessWidget {
  const _WeekSummary({required this.stats});

  final TripStats stats;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This week',
            style: (text.labelLarge ?? const TextStyle()).copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          ValueListenableBuilder<SpeedUnit>(
            valueListenable: AppState.unitSpeed,
            builder: (context, unit, _) => Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: 'Distance',
                    value: UnitsFormat.distance(stats.distanceKm, unit),
                  ),
                ),
                Expanded(
                  child: _Metric(
                    label: 'Time',
                    value: formatTripDuration(stats.duration),
                  ),
                ),
                Expanded(
                  child: _Metric(
                    label: 'Avg score',
                    value: stats.score?.toString() ?? '—',
                    accent: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: (text.titleLarge ?? const TextStyle()).copyWith(
            color: accent ? AppColors.primary : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: (text.bodySmall ?? const TextStyle())
              .copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

/// One drive: date, distance, duration and a score badge.
class _TripRow extends StatelessWidget {
  const _TripRow({required this.trip, required this.onTap});

  final Trip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final DateFormat day = DateFormat('EEE d MMM');
    final DateFormat time = DateFormat.Hm();

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: const Icon(Icons.route_rounded,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${day.format(trip.startedAt)} · '
                  '${time.format(trip.startedAt)}',
                  style: (text.bodyLarge ?? const TextStyle()).copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                ValueListenableBuilder<SpeedUnit>(
                  valueListenable: AppState.unitSpeed,
                  builder: (context, unit, _) => Text(
                    '${UnitsFormat.distance(trip.distanceKm, unit)} · '
                    '${formatTripDuration(trip.duration)}'
                    '${trip.events.isEmpty ? '' : ' · ${trip.events.length} harsh'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: (text.bodySmall ?? const TextStyle())
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _ScoreBadge(score: trip.score),
        ],
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final Color tint = score >= 90
        ? AppColors.success
        : (score >= 70 ? AppColors.ratingStar : AppColors.primaryGradientEnd);

    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.18),
        shape: BoxShape.circle,
        border: Border.all(color: tint, width: 1.5),
      ),
      child: Text(
        '$score',
        style: (Theme.of(context).textTheme.titleSmall ?? const TextStyle())
            .copyWith(color: tint, fontWeight: FontWeight.w700),
      ),
    );
  }
}
