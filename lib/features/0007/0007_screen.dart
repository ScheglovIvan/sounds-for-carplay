import 'dart:async';

import 'package:flutter/material.dart';

import 'package:drivana/core/app_state.dart';
import 'package:drivana/core/format/units_format.dart';
import 'package:drivana/core/models/now_playing.dart';
import 'package:drivana/core/models/user_settings.dart';
import 'package:drivana/core/router/app_router.dart';
import 'package:drivana/core/services/apple_music_service.dart';
import 'package:drivana/core/services/location_service.dart';
import 'package:drivana/core/services/notification_service.dart';
import 'package:drivana/core/services/purchase_flow.dart';
import 'package:drivana/ui/components/components.dart';

/// The Drive tab — Focus Drive home (app_spec id "0007").
///
/// The app's landing screen after onboarding/paywall: it explains and launches
/// the immersive Focus Drive board (screen "0014"), asks for the permissions
/// that keep the map / weather / clock tiles live, links to the Setup Guide and
/// previews what those tiles look like.
///
/// Sits inside the main bottom tab bar (Drive · Trips · Sounds · Car). Copy and
/// icons are paraphrased/restyled from the source; styling is owned by the
/// design system.
class Screen_0007 extends StatefulWidget {
  const Screen_0007({super.key});

  @override
  State<Screen_0007> createState() => _Screen_0007State();
}

class _Screen_0007State extends State<Screen_0007> {
  Timer? _ticker;
  DateTime _now = DateTime.now();
  bool _locationOn = false;

  @override
  void initState() {
    super.initState();
    _locationOn = LocationService.instance.granted.value;
    // Reflect a notification grant the user may have changed in iOS Settings.
    unawaited(NotificationService.instance.refresh());
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// The immersive board is one of the spec's premium "screen upgrades", so it
  /// is gated: a free user is sent to the paywall and lands in Focus Drive
  /// straight away if they subscribe. The rest of this tab (permissions, live
  /// previews) stays free.
  Future<void> _openFocusDrive() async {
    if (!await PurchaseFlow.ensurePro(context)) return;
    if (mounted) AppRouter.go(context, '0014');
  }

  /// Explain why location helps, then hand off to the REAL iOS dialog. The
  /// button that gets here is labelled neutrally ("Continue") — this app never
  /// tells the user how to answer the system prompt (App Store 5.1.1(iv)).
  Future<void> _requestLocation() async {
    if (_locationOn) return;
    final bool granted = await LocationService.instance.ensurePermission();
    if (granted && mounted) setState(() => _locationOn = true);
  }

  /// Same for notifications: the priming card explains the why, the real iOS
  /// authorization prompt does the asking.
  Future<void> _requestNotifications() async {
    await NotificationService.instance.request();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(
        title: 'Focus Drive',
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.tune_rounded),
          color: AppColors.textPrimary,
          onPressed: () => AppRouter.go(context, '0003'),
        ),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: AppState.isPro,
            builder: (context, isPro, _) {
              if (isPro) return const SizedBox.shrink();
              return AppProBadge(
                compact: true,
                onPressed: () => AppRouter.go(context, 'paywall_special'),
              );
            },
          ),
        ],
      ),
      bottomBar: const AppMainTabBar(current: AppMainTab.drive),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppDimens.gutter,
          8,
          AppDimens.gutter,
          24,
        ),
        children: [
          // Leads the tab: the screens fed by what Focus Drive records (Drive
          // Score, Trips) plus the two setup destinations.
          const AppSectionHeader(
            title: 'Your driving',
            padding: EdgeInsets.fromLTRB(4, 4, 4, 12),
          ),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                AppListTile(
                  title: 'Drive Score',
                  subtitle: 'How smooth your recent drives have been',
                  leadingIcon: Icons.speed_rounded,
                  onTap: () => AppRouter.go(context, 'safety_score'),
                ),
                const _Divider(),
                AppListTile(
                  title: 'Trips',
                  subtitle: 'Distance, duration and score per drive',
                  leadingIcon: Icons.route_rounded,
                  onTap: () => Navigator.of(context).pushNamedAndRemoveUntil(
                    AppMainTab.trips.route,
                    (route) => false,
                  ),
                ),
                const _Divider(),
                AppListTile(
                  title: 'Break Reminders',
                  subtitle: 'Get nudged to stop and stretch on long drives',
                  leadingIcon: Icons.free_breakfast_rounded,
                  onTap: () => AppRouter.go(context, 'break_reminders'),
                ),
                const _Divider(),
                AppListTile(
                  title: 'Setup Guide',
                  subtitle: 'Wire your departure and arrival cues to Shortcuts',
                  leadingIcon: Icons.auto_fix_high_rounded,
                  onTap: () => AppRouter.go(context, 'connection_guide'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Rebuilds the moment Apphud confirms PRO, so the lock lifts right
          // after a purchase without an app restart.
          ValueListenableBuilder<bool>(
            valueListenable: AppState.isPro,
            builder: (context, isPro, _) => _LaunchCard(
              locked: !isPro,
              onStart: _openFocusDrive,
            ),
          ),
          const SizedBox(height: 20),
          _PermissionsSection(
            locationOn: _locationOn,
            onRequestLocation: _requestLocation,
            onRequestNotifications: _requestNotifications,
          ),
          const SizedBox(height: 8),
          const AppSectionHeader(
            title: 'On your board',
            padding: EdgeInsets.fromLTRB(4, AppDimens.gutter, 4, 12),
          ),
          _PreviewGrid(now: _now),
        ],
      ),
    );
  }
}

/// Hero card that describes and launches the immersive Focus Drive board.
class _LaunchCard extends StatelessWidget {
  const _LaunchCard({required this.onStart, required this.locked});

  final VoidCallback onStart;

  /// True for free users: the card shows a PRO lock and the CTA opens the
  /// paywall instead of Focus Drive.
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      gradient: AppGradients.cta,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.onPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: const Icon(Icons.directions_car_filled_rounded,
                    color: AppColors.onPrimary, size: 26),
              ),
              const SizedBox(width: 12),
              const AppBadge(label: 'CALM BOARD', tone: AppBadgeTone.neutral),
              if (locked) ...[
                const Spacer(),
                const AppBadge(
                  label: 'PRO',
                  tone: AppBadgeTone.premium,
                  icon: Icons.lock_rounded,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Focus Drive',
            style: (Theme.of(context).textTheme.headlineSmall ??
                    const TextStyle())
                .copyWith(
              color: AppColors.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'One calm, glanceable board for the road — a big clock, your route, '
            'what’s playing and the local weather, all at a glance.',
            style: (Theme.of(context).textTheme.bodyMedium ?? const TextStyle())
                .copyWith(color: AppColors.onPrimary.withValues(alpha: 0.9)),
          ),
          const SizedBox(height: 18),
          AppButton(
            label: locked ? 'Unlock Focus Drive' : 'Start Focus Drive',
            variant: AppButtonVariant.white,
            icon: locked ? Icons.lock_rounded : Icons.play_arrow_rounded,
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}

/// Permission priming that keeps the live tiles fed.
///
/// App Store 5.1.1(iv): a custom screen shown BEFORE a system dialog may
/// explain WHY the permission is useful, but must not tell the user how to
/// answer it — so every button here reads "Continue", never "Allow"/"Enable".
class _PermissionsSection extends StatelessWidget {
  const _PermissionsSection({
    required this.locationOn,
    required this.onRequestLocation,
    required this.onRequestNotifications,
  });

  final bool locationOn;
  final VoidCallback onRequestLocation;
  final VoidCallback onRequestNotifications;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          title: 'Permissions',
          padding: EdgeInsets.fromLTRB(4, 4, 4, 12),
        ),
        if (locationOn)
          AppBanner(
            tone: AppBannerTone.info,
            title: 'Location connected',
            message: 'Map and weather tiles will refresh as you move.',
            icon: Icons.check_circle_rounded,
          )
        else
          AppBanner(
            title: 'Share your location',
            message:
                'Drivana uses your location for the live map and local weather '
                'in Focus Drive.',
            icon: Icons.location_on_rounded,
            trailing: AppButton(
              label: 'Continue',
              variant: AppButtonVariant.gradient,
              expanded: false,
              height: 40,
              onPressed: onRequestLocation,
            ),
            onTap: onRequestLocation,
          ),
        const SizedBox(height: 10),
        ValueListenableBuilder<bool>(
          valueListenable: AppState.notificationsEnabled,
          builder: (context, enabled, _) {
            if (enabled) {
              return AppBanner(
                tone: AppBannerTone.info,
                title: 'Alerts on',
                message: 'We’ll nudge you about breaks and your arrival cues.',
                icon: Icons.notifications_active_rounded,
              );
            }
            return AppBanner(
              title: 'Turn on alerts',
              message:
                  'Alerts are how Drivana nudges you to take a break and lets '
                  'you know your arrival cue fired.',
              icon: Icons.notifications_rounded,
              trailing: AppButton(
                label: 'Continue',
                variant: AppButtonVariant.gradient,
                expanded: false,
                height: 40,
                onPressed: onRequestNotifications,
              ),
              onTap: onRequestNotifications,
            );
          },
        ),
      ],
    );
  }
}

/// A 2x2 preview of the Focus Drive tiles.
class _PreviewGrid extends StatelessWidget {
  const _PreviewGrid({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _PreviewTile(
                icon: Icons.schedule_rounded,
                label: 'Clock',
                value: '${_two(now.hour)}:${_two(now.minute)}',
                accent: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ValueListenableBuilder<TemperatureUnit>(
                valueListenable: AppState.unitTemperature,
                builder: (context, unit, _) => _PreviewTile(
                  icon: Icons.wb_sunny_rounded,
                  label: 'Weather',
                  value: '${UnitsFormat.temperature(21, unit)} Clear',
                  accent: AppColors.ratingStar,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Expanded(
              child: _PreviewTile(
                icon: Icons.map_rounded,
                label: 'Navigation',
                value: 'Live map',
                accent: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            // Bound to the REAL system now-playing item (what the Music app is
            // playing), never an invented track name.
            Expanded(
              child: ValueListenableBuilder<NowPlayingInfo>(
                valueListenable: AppleMusicService.instance.nowPlaying,
                builder: (context, info, _) => _PreviewTile(
                  icon: Icons.music_note_rounded,
                  label: 'Now playing',
                  value: info.hasTrack
                      ? (info.title ?? info.artist!)
                      : 'Nothing playing',
                  accent: AppColors.primaryGradientEnd,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PreviewTile extends StatelessWidget {
  const _PreviewTile({
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
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: (Theme.of(context).textTheme.bodySmall ?? const TextStyle())
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: (Theme.of(context).textTheme.titleSmall ?? const TextStyle())
                .copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Hairline separator between rows inside a grouped [AppCard].
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

String _two(int v) => v.toString().padLeft(2, '0');
