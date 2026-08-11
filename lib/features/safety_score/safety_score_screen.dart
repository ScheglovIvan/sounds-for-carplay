import 'dart:math' as math;

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

/// Drive Score (app_spec id "safety_score", route `/safety_score`).
///
/// Everything on this screen is COMPUTED from the drives the app actually
/// recorded — the gauge, the event counts, the 7-day trend and the recent-event
/// list all read [TripStore]. With no recorded drives it shows an honest empty
/// state instead of a demo score.
///
/// Free users get this week; the all-time window is PRO
/// (`app_spec.json` › screens › safety_score).
class Screen_safety_score extends StatefulWidget {
  const Screen_safety_score({super.key});

  @override
  State<Screen_safety_score> createState() => _Screen_safety_scoreState();
}

class _Screen_safety_scoreState extends State<Screen_safety_score> {
  final TripStore _store = TripStore.instance;

  /// False = this week (free), true = all time (PRO).
  bool _allTime = false;

  Future<void> _selectAllTime() async {
    if (_allTime) return;
    if (!await PurchaseFlow.ensurePro(context)) return;
    if (mounted) setState(() => _allTime = true);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(
        title: 'Drive Score',
        showBack: true,
        onBack: () {
          final NavigatorState nav = Navigator.of(context);
          if (nav.canPop()) {
            nav.pop();
          } else {
            AppRouter.go(context, '0007');
          }
        },
        actions: [
          IconButton(
            tooltip: 'Trips',
            icon: const Icon(Icons.route_rounded),
            color: AppColors.textPrimary,
            onPressed: () => AppRouter.go(context, 'trips'),
          ),
        ],
      ),
      bottomBar: const AppMainTabBar(current: AppMainTab.drive),
      body: ValueListenableBuilder<List<Trip>>(
        valueListenable: _store.trips,
        builder: (context, allTrips, _) {
          if (allTrips.isEmpty) {
            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppDimens.gutter),
              child: AppEmptyState(
                icon: Icons.speed_rounded,
                title: 'No score yet',
                message:
                    'Your Drive Score is worked out from the drives Drivana '
                    'records. Start a Focus Drive and it will appear here '
                    'after your first trip.',
                actionLabel: 'Go to Focus Drive',
                onAction: () => Navigator.of(context).pushNamedAndRemoveUntil(
                  AppMainTab.drive.route,
                  (route) => false,
                ),
              ),
            );
          }

          final List<Trip> scoped = _allTime ? allTrips : _store.thisWeek();
          final TripStats stats = TripStats.from(scoped);

          return ValueListenableBuilder<bool>(
            valueListenable: AppState.isPro,
            builder: (context, isPro, _) => ListView(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.gutter,
                8,
                AppDimens.gutter,
                28,
              ),
              children: [
                _PeriodToggle(
                  allTime: _allTime,
                  locked: !isPro,
                  onThisWeek: () => setState(() => _allTime = false),
                  onAllTime: _selectAllTime,
                ),
                const SizedBox(height: 16),
                _ScoreCard(stats: stats, allTime: _allTime),
                const SizedBox(height: 16),
                _EventStatRow(stats: stats),
                const SizedBox(height: 20),
                const AppSectionHeader(
                  title: 'Last 7 days',
                  padding: EdgeInsets.fromLTRB(4, 0, 4, 12),
                ),
                _TrendChart(trend: _store.weeklyTrend()),
                const SizedBox(height: 20),
                AppSectionHeader(
                  title: 'Recent events',
                  actionLabel: 'Trips',
                  onAction: () => AppRouter.go(context, 'trips'),
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                ),
                _RecentEvents(events: _store.recentEvents()),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Period toggle ─────────────────────────────────────────────────────────────

class _PeriodToggle extends StatelessWidget {
  const _PeriodToggle({
    required this.allTime,
    required this.locked,
    required this.onThisWeek,
    required this.onAllTime,
  });

  final bool allTime;

  /// True for free users — the All time segment carries a PRO lock.
  final bool locked;
  final VoidCallback onThisWeek;
  final VoidCallback onAllTime;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(5),
      radius: AppRadii.pill,
      child: Row(
        children: [
          Expanded(
            child: _Segment(
              label: 'This week',
              selected: !allTime,
              onTap: onThisWeek,
            ),
          ),
          Expanded(
            child: _Segment(
              label: 'All time',
              selected: allTime,
              icon: locked ? Icons.lock_rounded : null,
              onTap: onAllTime,
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : Colors.transparent,
      borderRadius: AppRadii.rPill,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color:
                      selected ? AppColors.onPrimary : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: (Theme.of(context).textTheme.labelLarge ??
                        const TextStyle())
                    .copyWith(
                  color:
                      selected ? AppColors.onPrimary : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Score gauge ───────────────────────────────────────────────────────────────

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.stats, required this.allTime});

  final TripStats stats;
  final bool allTime;

  static String _verdict(int score) {
    if (score >= 90) return 'Excellent — smooth and calm';
    if (score >= 75) return 'Good — a few sharp moments';
    if (score >= 55) return 'Mixed — ease off the pedals';
    return 'Rough — plenty of harsh moments';
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final int? score = stats.score;

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          SizedBox(
            width: 172,
            height: 172,
            child: CustomPaint(
              painter: _GaugePainter(
                value: (score ?? 0) / 100.0,
                track: AppColors.textSecondary.withValues(alpha: 0.2),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      score?.toString() ?? '—',
                      style: (text.displaySmall ?? const TextStyle()).copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'out of 100',
                      style: (text.bodySmall ?? const TextStyle())
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            score == null
                ? 'No drives in this period'
                : _verdict(score),
            textAlign: TextAlign.center,
            style: (text.titleSmall ?? const TextStyle()).copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          ValueListenableBuilder<SpeedUnit>(
            valueListenable: AppState.unitSpeed,
            builder: (context, unit, _) => Text(
              stats.isEmpty
                  ? (allTime ? 'All time' : 'This week')
                  : '${stats.tripCount} '
                      '${stats.tripCount == 1 ? 'drive' : 'drives'} · '
                      '${UnitsFormat.distance(stats.distanceKm, unit)} · '
                      '${_duration(stats.duration)}',
              textAlign: TextAlign.center,
              style: (text.bodySmall ?? const TextStyle())
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// A thick rounded arc gauge. Painted rather than imported so the score ring
/// picks up the design-system gradient colors.
class _GaugePainter extends CustomPainter {
  const _GaugePainter({required this.value, required this.track});

  final double value;
  final Color track;

  static const double _startAngle = math.pi * 0.75;
  static const double _sweep = math.pi * 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    const double stroke = 16;
    final Rect rect = Offset.zero & size;
    final Rect arcRect = rect.deflate(stroke / 2 + 2);

    final Paint base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = track;
    canvas.drawArc(arcRect, _startAngle, _sweep, false, base);

    final double clamped = value.clamp(0.0, 1.0);
    if (clamped <= 0) return;

    final Paint progress = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = AppGradients.cta.createShader(arcRect);
    canvas.drawArc(arcRect, _startAngle, _sweep * clamped, false, progress);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.track != track;
}

// ── Event stats ───────────────────────────────────────────────────────────────

class _EventStatRow extends StatelessWidget {
  const _EventStatRow({required this.stats});

  final TripStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.trending_down_rounded,
            label: 'Harsh braking',
            value: '${stats.harshBraking}',
            accent: AppColors.primaryGradientEnd,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            icon: Icons.trending_up_rounded,
            label: 'Hard accel.',
            value: '${stats.hardAcceleration}',
            accent: AppColors.ratingStar,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            icon: Icons.spa_rounded,
            label: 'Smooth trips',
            value: '${stats.smoothTrips}',
            accent: AppColors.success,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Column(
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: (text.titleLarge ?? const TextStyle()).copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: (text.bodySmall ?? const TextStyle())
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ── 7-day trend ───────────────────────────────────────────────────────────────

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.trend});

  final List<({DateTime day, int? score})> trend;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final DateFormat weekday = DateFormat('E');

    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
      child: SizedBox(
        height: 150,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final entry in trend)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        entry.score?.toString() ?? '',
                        style: (text.labelSmall ?? const TextStyle()).copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // A day with no drive draws a faint stub, never an
                            // invented score.
                            final int? score = entry.score;
                            final double fraction =
                                score == null ? 0.06 : (score / 100).clamp(0.06, 1.0);
                            return Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                height: constraints.maxHeight * fraction,
                                decoration: BoxDecoration(
                                  gradient: score == null
                                      ? null
                                      : AppGradients.cta,
                                  color: score == null
                                      ? AppColors.textSecondary
                                          .withValues(alpha: 0.25)
                                      : null,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        weekday.format(entry.day).substring(0, 1),
                        style: (text.labelSmall ?? const TextStyle())
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Recent events ─────────────────────────────────────────────────────────────

class _RecentEvents extends StatelessWidget {
  const _RecentEvents({required this.events});

  final List<DriveEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return AppCard(
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No harsh braking or hard acceleration recorded. Nicely done.',
                style: (Theme.of(context).textTheme.bodyMedium ??
                        const TextStyle())
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    final DateFormat stamp = DateFormat('E d MMM · HH:mm');

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (int i = 0; i < events.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: AppColors.textSecondary.withValues(alpha: 0.12),
              ),
            AppListTile(
              title: events[i].kind.label,
              subtitle: stamp.format(events[i].at),
              leadingIcon: events[i].kind == DriveEventKind.harshBraking
                  ? Icons.trending_down_rounded
                  : Icons.trending_up_rounded,
              leadingColor: events[i].kind == DriveEventKind.harshBraking
                  ? AppColors.primaryGradientEnd
                  : AppColors.ratingStar,
              showChevron: false,
              trailing: AppBadge(
                label: events[i].severityLabel.toUpperCase(),
                tone: events[i].severity >= 0.66
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

String _duration(Duration d) {
  final int hours = d.inHours;
  final int minutes = d.inMinutes % 60;
  if (hours > 0) return '${hours}h ${minutes}m';
  return '${minutes}m';
}
