import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:drivana/core/format/units_format.dart';
import 'package:drivana/core/models/now_playing.dart';
import 'package:drivana/core/models/user_settings.dart';
import 'package:drivana/core/router/app_router.dart';
import 'package:drivana/core/services/apple_music_service.dart';
import 'package:drivana/core/services/break_reminder_service.dart';
import 'package:drivana/core/services/location_service.dart';
import 'package:drivana/core/services/trip_recorder.dart';
import 'package:drivana/core/state.dart';
import 'package:drivana/ui/components/components.dart';

import 'widgets/drive_status_bar.dart';
import 'widgets/live_map.dart';

/// Focus Drive (Live) — the immersive, landscape driving board
/// (app_spec id "0014").
///
/// Reproduces the original app's real behaviour: a landscape board with a live
/// status bar (real clock/battery/network) and a left app rail that pages
/// between a glance board (live Apple map, weather, and the system now-playing
/// tile) and a full now-playing page for the SYSTEM track (opened and started
/// in the Apple Music app itself) with real transport control.
/// See `CAPABILITIES.md` for the documented limits.
class Screen_0014 extends StatefulWidget {
  const Screen_0014({super.key});

  @override
  State<Screen_0014> createState() => _Screen_0014State();
}

class _Screen_0014State extends State<Screen_0014> {
  final LocationService _location = LocationService.instance;
  final PageController _pageController = PageController();

  int _page = 0;
  bool _locationOn = false;
  bool _locating = false;

  /// True while a break nudge is waiting to be acknowledged.
  bool _breakDue = false;

  /// True when the last attempt ended with no usable fix at all — the map then
  /// offers Retry instead of spinning forever.
  bool _locationFailed = false;
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    // Immersive landscape orientation while driving; restored on exit.
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _locationOn = _location.granted.value;
    if (_locationOn) _enableLocation();
    // Start mirroring the system now-playing item (asks for the real Apple
    // Music authorization the first time).
    AppleMusicService.instance.start();
    // Break reminders count the real elapsed drive time (see TripRecorder).
    BreakReminderService.instance.dueAt.addListener(_onBreakDue);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    BreakReminderService.instance.dueAt.removeListener(_onBreakDue);
    // Closing the board ends the drive: the recorder saves the real trip (or
    // discards a too-short one) so it shows up in Trips / Drive Score.
    unawaited(TripRecorder.instance.stop());
    _pageController.dispose();
    super.dispose();
  }

  void _onBreakDue() {
    if (!mounted) return;
    if (BreakReminderService.instance.dueAt.value != null) {
      setState(() => _breakDue = true);
    }
  }

  /// Paint the map from the OS's cached fix first (instant when there is one),
  /// then refine with a fresh, time-limited fix. Returns whether we ended up
  /// with any usable position.
  Future<bool> _loadPosition() async {
    bool located = false;

    final cached = await _location.lastKnownPosition();
    if (!mounted) return false;
    if (cached != null) {
      located = true;
      setState(() {
        _lat = cached.latitude;
        _lng = cached.longitude;
      });
    }

    final fresh = await _location.currentPosition();
    if (!mounted) return located;
    if (fresh != null) {
      located = true;
      setState(() {
        _lat = fresh.latitude;
        _lng = fresh.longitude;
      });
    }
    return located;
  }

  /// Trigger the REAL iOS location dialog, then centre the map on the fix.
  ///
  /// [_locating] is cleared in a `finally`, so the spinner always goes away —
  /// permission denied, no fix, or an unexpected error included.
  Future<void> _enableLocation() async {
    if (_locating) return;
    setState(() {
      _locating = true;
      _locationFailed = false;
    });
    try {
      final bool granted = await _location.ensurePermission();
      if (!mounted) return;
      if (!granted) {
        setState(() => _locationOn = false);
        return;
      }
      setState(() => _locationOn = true);
      // With a real fix available, start recording the drive: distance, route
      // and harsh events all come from the live GPS stream.
      unawaited(TripRecorder.instance.start());
      final bool located = await _loadPosition();
      if (!mounted) return;
      if (!located) setState(() => _locationFailed = true);
    } catch (_) {
      if (mounted) setState(() => _locationFailed = true);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _goToPage(int index) {
    setState(() => _page = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _exit() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      AppRouter.go(context, '0007');
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _DashboardPage(
        locationOn: _locationOn,
        locating: _locating,
        locationFailed: _locationFailed,
        lat: _lat,
        lng: _lng,
        onEnableLocation: _enableLocation,
      ),
      const _MusicPage(),
    ];

    return AppScaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
        child: Column(
          children: [
            DriveStatusBar(onClose: _exit),
            if (_breakDue) ...[
              const SizedBox(height: 8),
              _BreakNudge(onDismiss: () => setState(() => _breakDue = false)),
            ],
            const SizedBox(height: 10),
            Expanded(
              child: Row(
                children: [
                  _AppRail(
                    current: _page,
                    onSelect: _goToPage,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      // Rail-only switching: no horizontal swipe so drags over
                      // the map tile pan the map instead of flipping pages.
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (i) => setState(() => _page = i),
                      children: pages,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _PageDots(count: pages.length, index: _page),
          ],
        ),
      ),
    );
  }
}

/// The break reminder, raised by [BreakReminderService] after the configured
/// number of minutes of REAL recorded driving. Shown inline on the board (the
/// driver is looking here) and dismissed explicitly.
class _BreakNudge extends StatelessWidget {
  const _BreakNudge({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: AppGradients.cta,
        borderRadius: AppRadii.rSm,
      ),
      child: Row(
        children: [
          const Icon(Icons.free_breakfast_rounded,
              color: AppColors.onPrimary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Time for a break — pull over safely when you can.',
              style: (text.titleSmall ?? const TextStyle()).copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: onDismiss,
            child: Text(
              'Dismiss',
              style: (text.labelLarge ?? const TextStyle()).copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Left app rail ─────────────────────────────────────────────────────────────

class _AppRail extends StatelessWidget {
  const _AppRail({required this.current, required this.onSelect});

  final int current;
  final ValueChanged<int> onSelect;

  static const List<IconData> _icons = [
    Icons.dashboard_rounded,
    Icons.music_note_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.rLg,
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < _icons.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _RailButton(
              icon: _icons[i],
              selected: current == i,
              onTap: () => onSelect(i),
            ),
          ],
        ],
      ),
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: AppRadii.rSm),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            size: 22,
            color: selected ? AppColors.onPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == index
                  ? AppColors.primary
                  : AppColors.textSecondary.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}

// ── Page 0: glance dashboard (map + weather + now playing) ────────────────────

class _DashboardPage extends StatelessWidget {
  const _DashboardPage({
    required this.locationOn,
    required this.locating,
    required this.locationFailed,
    required this.lat,
    required this.lng,
    required this.onEnableLocation,
  });

  final bool locationOn;
  final bool locating;
  final bool locationFailed;
  final double? lat;
  final double? lng;
  final VoidCallback onEnableLocation;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Map tile ~40% of the glance width (left-center), matching the
        // original; the weather + now-playing cards fill the wider right column.
        Expanded(
          flex: 4,
          child: LiveMap(
            granted: locationOn,
            latitude: lat,
            longitude: lng,
            loading: locating,
            failed: locationFailed,
            onEnable: onEnableLocation,
            compact: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              Expanded(child: _WeatherTile()),
              SizedBox(height: 12),
              Expanded(child: _MusicTile()),
            ],
          ),
        ),
      ],
    );
  }
}

/// Weather tile. No public weather feed / API key is bundled, so this reflects a
/// neutral sample condition (documented in CAPABILITIES.md) — it never claims a
/// live reading. Temperature honours the user's unit setting.
class _WeatherTile extends StatelessWidget {
  const _WeatherTile();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wb_cloudy_rounded,
                  color: AppColors.ratingStar, size: 22),
              const Spacer(),
              Text(
                'Weather',
                style: (Theme.of(context).textTheme.bodySmall ??
                        const TextStyle())
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const Spacer(),
          ValueListenableBuilder<TemperatureUnit>(
            valueListenable: AppState.unitTemperature,
            builder: (context, unit, _) => FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                UnitsFormat.temperature(21, unit),
                style: (Theme.of(context).textTheme.headlineMedium ??
                        const TextStyle())
                    .copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Text(
            'Partly cloudy',
            style: (Theme.of(context).textTheme.bodySmall ?? const TextStyle())
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Open the Apple Music app so the user can start playback there. What they
/// play then appears in the tiles below via the system now-playing item.
Future<void> _openAppleMusic(BuildContext context) async {
  final bool ok = await AppleMusicService.instance.openAppleMusic();
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Apple Music isn’t available on this device')),
    );
  }
}

/// Album artwork from the system now-playing item, with the design-system
/// gradient tile as the fallback when the track carries none.
class _Artwork extends StatelessWidget {
  const _Artwork({required this.size, required this.artwork, this.radius});

  final double size;
  final ImageProvider? artwork;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final ImageProvider? image = artwork;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: image == null ? AppGradients.cta : null,
        color: image == null ? null : AppColors.background,
        borderRadius: BorderRadius.circular(radius ?? AppRadii.sm),
      ),
      child: image == null
          ? Icon(Icons.music_note_rounded,
              color: AppColors.onPrimary, size: size * 0.5)
          : Image(
              image: image,
              fit: BoxFit.cover,
              errorBuilder: (context, _, __) => Icon(
                Icons.album_rounded,
                color: AppColors.textSecondary,
                size: size * 0.5,
              ),
            ),
    );
  }
}

/// Compact now-playing tile: shows what the SYSTEM (the Music app) is playing.
///
/// The app plays nothing itself here — tapping opens Apple Music, and once the
/// user starts a track there its real title, artist and artwork appear below.
class _MusicTile extends StatelessWidget {
  const _MusicTile();

  @override
  Widget build(BuildContext context) {
    final AppleMusicService music = AppleMusicService.instance;
    final TextTheme text = Theme.of(context).textTheme;

    return ValueListenableBuilder<NowPlayingInfo>(
      valueListenable: music.nowPlaying,
      builder: (context, info, _) {
        if (!info.hasTrack) {
          return AppCard(
            onTap: () => _openAppleMusic(context),
            child: Row(
              children: [
                const _Artwork(size: 42, artwork: null),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Open Apple Music',
                        style: (text.titleSmall ?? const TextStyle()).copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Play something there — it shows up here',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: (text.bodySmall ?? const TextStyle())
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return ValueListenableBuilder<bool>(
          valueListenable: music.canControl,
          builder: (context, canControl, _) {
            return AppCard(
              child: Row(
                children: [
                  _Artwork(size: 42, artwork: info.artwork),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          info.title ?? 'Now playing',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              (text.titleSmall ?? const TextStyle()).copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (info.artist != null)
                          Text(
                            info.artist!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: (text.bodySmall ?? const TextStyle())
                                .copyWith(color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                  // Transport is shown ONLY when the system player is really
                  // reachable — never a button that does nothing.
                  if (canControl)
                    _RoundControl(
                      icon: info.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      onTap: () => music.togglePlay(),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── Page 2: full now playing ──────────────────────────────────────────────────

class _MusicPage extends StatelessWidget {
  const _MusicPage();

  @override
  Widget build(BuildContext context) {
    final AppleMusicService music = AppleMusicService.instance;
    final TextTheme text = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: ValueListenableBuilder<NowPlayingInfo>(
        valueListenable: music.nowPlaying,
        builder: (context, info, _) {
          if (!info.hasTrack) {
            // Nothing is playing on the system: the only honest action is to
            // open Apple Music so the user can start something there.
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _Artwork(size: 72, artwork: null, radius: AppRadii.md),
                const SizedBox(height: 16),
                Text(
                  'Open Apple Music',
                  style: (text.titleMedium ?? const TextStyle()).copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Start a song in Apple Music and it appears here — Focus '
                  'Drive shows and controls what your iPhone is playing.',
                  textAlign: TextAlign.center,
                  style: (text.bodySmall ?? const TextStyle())
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: 260,
                  child: AppButton(
                    label: 'Open Apple Music',
                    variant: AppButtonVariant.gradient,
                    icon: Icons.music_note_rounded,
                    onPressed: () => _openAppleMusic(context),
                  ),
                ),
              ],
            );
          }

          return ValueListenableBuilder<bool>(
            valueListenable: music.canControl,
            builder: (context, canControl, _) {
              return Row(
                children: [
                  _Artwork(
                    size: 120,
                    artwork: info.artwork,
                    radius: AppRadii.md,
                  ),
                  const SizedBox(width: 22),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          info.title ?? 'Now playing',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              (text.headlineSmall ?? const TextStyle()).copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (info.artist != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            info.artist!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: (text.bodyMedium ?? const TextStyle())
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                        // The position is optional: the system reports no
                        // elapsed time until playback has actually been
                        // prepared. We then simply omit the progress figure —
                        // the track and its controls stay on screen.
                        if (info.hasPosition) ...[
                          const SizedBox(height: 14),
                          _Progress(info: info),
                        ],
                        // Transport drives the SYSTEM player. If that native
                        // path isn't available the buttons are hidden rather
                        // than shown dead.
                        if (canControl) ...[
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              _RoundControl(
                                icon: Icons.skip_previous_rounded,
                                onTap: () => music.previous(),
                                filled: false,
                              ),
                              const SizedBox(width: 14),
                              _RoundControl(
                                icon: info.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                onTap: () => music.togglePlay(),
                                size: 58,
                              ),
                              const SizedBox(width: 14),
                              _RoundControl(
                                icon: Icons.skip_next_rounded,
                                onTap: () => music.next(),
                                filled: false,
                              ),
                            ],
                          ),
                        ] else ...[
                          const SizedBox(height: 14),
                          Text(
                            'Control playback from Apple Music.',
                            style: (text.bodySmall ?? const TextStyle())
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// Elapsed / remaining readout for the current system track.
///
/// Only built when [NowPlayingInfo.hasPosition] — the system reports no elapsed
/// time until playback has been prepared, and an unknown position is shown as
/// nothing at all rather than as a fake `0:00`. The bar itself additionally
/// needs a usable track length.
class _Progress extends StatelessWidget {
  const _Progress({required this.info});

  final NowPlayingInfo info;

  static String _clock(Duration d) {
    final int minutes = d.inMinutes;
    final String seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final Duration elapsed = info.elapsed!;
    final Duration? reported = info.duration;
    // A zero / unknown length still gets the elapsed readout, just no bar.
    final Duration? total =
        (reported != null && reported.inMilliseconds > 0) ? reported : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (total != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: (elapsed.inMilliseconds / total.inMilliseconds)
                  .clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: AppColors.textSecondary.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 6),
        ],
        Text(
          total != null
              ? '${_clock(elapsed)} / ${_clock(total)}'
              : _clock(elapsed),
          style: (text.bodySmall ?? const TextStyle())
              .copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _RoundControl extends StatelessWidget {
  const _RoundControl({
    required this.icon,
    required this.onTap,
    this.size = 46,
    this.filled = true,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.primary : AppColors.background,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            color: filled ? AppColors.onPrimary : AppColors.textPrimary,
            size: size * 0.5,
          ),
        ),
      ),
    );
  }
}
