import 'dart:async';

import 'package:apple_maps_flutter/apple_maps_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'package:drivana/core/services/location_service.dart';
import 'package:drivana/ui/theme/app_theme.dart';

/// A real, live, interactive Apple Maps (native MapKit) view for Focus Drive.
///
/// No API key and no static image: on iOS this is the native [AppleMap] centred
/// on the user's real coordinates with the system "my location" dot. It
/// subscribes to [LocationService.positionStream] and, as new GPS fixes arrive,
/// moves the camera so the map FOLLOWS the user. Pinch-zoom and pan gestures
/// stay enabled. When location is not yet granted it shows an inline enable
/// prompt; on platforms without MapKit (web preview, etc.) it shows an honest
/// on-device note rather than a fake map (see `CAPABILITIES.md`).
class LiveMap extends StatefulWidget {
  const LiveMap({
    super.key,
    required this.granted,
    required this.latitude,
    required this.longitude,
    required this.onEnable,
    this.loading = false,
    this.failed = false,
    this.compact = false,
  });

  /// Whether location permission is held.
  final bool granted;

  /// The user's real coordinates from the initial fix, or null while
  /// acquiring/denied. The live stream takes over once the map is created.
  final double? latitude;
  final double? longitude;

  /// Enable location / retry after a failed attempt.
  final VoidCallback onEnable;
  final bool loading;

  /// True when the last attempt finished WITHOUT a usable fix. The map then
  /// shows a short explanatory state with a Retry action instead of spinning
  /// forever.
  final bool failed;

  /// Smaller framing for the dashboard tile vs. the full map page.
  final bool compact;

  @override
  State<LiveMap> createState() => _LiveMapState();
}

class _LiveMapState extends State<LiveMap> {
  AppleMapController? _controller;
  StreamSubscription<Position>? _positionSub;

  // The latest live coordinates (seeded from the parent's one-shot fix, then
  // driven by the position stream).
  double? _lat;
  double? _lng;

  bool get _mapKitAvailable =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  bool get _hasFix => _lat != null && _lng != null;

  @override
  void initState() {
    super.initState();
    _lat = widget.latitude;
    _lng = widget.longitude;
    if (widget.granted) _startFollowing();
  }

  @override
  void didUpdateWidget(covariant LiveMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Seed from the parent's fix until the stream has produced one.
    if (_positionSub == null) {
      _lat = widget.latitude ?? _lat;
      _lng = widget.longitude ?? _lng;
    }
    if (widget.granted && !oldWidget.granted) {
      _startFollowing();
    } else if (!widget.granted && oldWidget.granted) {
      _stopFollowing();
    }
  }

  /// Subscribe to the real GPS stream and follow the user as fixes arrive.
  void _startFollowing() {
    _positionSub ??=
        LocationService.instance.positionStream().listen((Position pos) {
      if (!mounted) return;
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
      _controller?.moveCamera(
        CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)),
      );
    });
  }

  void _stopFollowing() {
    _positionSub?.cancel();
    _positionSub = null;
  }

  @override
  void dispose() {
    _stopFollowing();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadii.rMd,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _base(context),
          if (widget.granted && _hasFix && _mapKitAvailable)
            Positioned(
              left: 12,
              bottom: 12,
              child: _pill(context, Icons.my_location_rounded, 'Live'),
            ),
        ],
      ),
    );
  }

  Widget _base(BuildContext context) {
    if (!widget.granted) {
      // Permission priming (App Store 5.1.1(iv)): explain WHY location helps,
      // but never tell the user how to answer the system dialog that follows —
      // hence the neutral "Continue".
      return _prompt(
        context,
        icon: Icons.location_on_rounded,
        title: 'Location for the live map',
        subtitle: widget.loading
            ? 'Locating…'
            : 'Used for the live map and your trip stats.',
        showSpinner: widget.loading,
        actionLabel: widget.loading ? null : 'Continue',
        actionIcon: Icons.arrow_forward_rounded,
        onTap: widget.loading ? null : widget.onEnable,
      );
    }

    if (!_mapKitAvailable) {
      return _prompt(
        context,
        icon: Icons.map_rounded,
        title: 'Live Apple Maps runs on device',
        subtitle: 'Native MapKit renders on your iPhone.',
        onTap: null,
      );
    }

    if (!_hasFix) {
      // No fix and nothing still running: say so and offer a way out, never an
      // endless spinner.
      if (widget.failed && !widget.loading) {
        return _prompt(
          context,
          icon: Icons.location_disabled_rounded,
          title: "Couldn't get your location",
          subtitle: 'Check Location Services and your signal.',
          actionLabel: 'Retry',
          onTap: widget.onEnable,
        );
      }
      return _prompt(
        context,
        icon: Icons.my_location_rounded,
        title: 'Locating…',
        subtitle: 'Centring the map on your position.',
        showSpinner: true,
        onTap: null,
      );
    }

    final LatLng target = LatLng(_lat!, _lng!);
    return AppleMap(
      initialCameraPosition: CameraPosition(target: target, zoom: 15.5),
      // System "my location" blue dot.
      myLocationEnabled: true,
      // Normal interactive map — pinch zoom and pan.
      zoomGesturesEnabled: true,
      scrollGesturesEnabled: true,
      annotations: <Annotation>{
        Annotation(
          annotationId: AnnotationId('me'),
          position: target,
        ),
      },
      onMapCreated: (AppleMapController controller) {
        _controller = controller;
        // Ensure the camera is on the freshest fix as soon as the map exists.
        if (_hasFix) {
          controller.moveCamera(CameraUpdate.newLatLng(LatLng(_lat!, _lng!)));
        }
      },
    );
  }

  Widget _prompt(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool showSpinner = false,
    String? actionLabel,
    IconData actionIcon = Icons.refresh_rounded,
  }) {
    final Widget content = Container(
      color: AppColors.surface,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSpinner)
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.6,
                color: AppColors.primary,
              ),
            )
          else
            Icon(icon, color: AppColors.primary, size: widget.compact ? 26 : 34),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: (Theme.of(context).textTheme.titleSmall ?? const TextStyle())
                .copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: (Theme.of(context).textTheme.bodySmall ?? const TextStyle())
                .copyWith(color: AppColors.textSecondary),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.16),
                borderRadius: AppRadii.rPill,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(actionIcon, size: 15, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    actionLabel,
                    style: (Theme.of(context).textTheme.labelLarge ??
                            const TextStyle())
                        .copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: content),
    );
  }

  Widget _pill(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.7),
        borderRadius: AppRadii.rPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: (Theme.of(context).textTheme.labelSmall ?? const TextStyle())
                .copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
