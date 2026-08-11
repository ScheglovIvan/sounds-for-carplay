import 'package:flutter/material.dart';

import 'app_bottom_bar.dart';

/// The app's four bottom-tab roots: Drive · Trips · Sounds · Car.
///
/// Every root screen renders the SAME bar through [AppMainTabBar], so the four
/// destinations, their order, their labels and their icons live in exactly one
/// place. Each entry maps to a screen id already registered in `AppRouter`, so
/// the `iosforge://screen/<id>` deep links and `/#/screen/<id>` previews keep
/// working unchanged.
enum AppMainTab {
  /// Focus Drive home — the app's landing screen after onboarding/paywall.
  drive(
    id: '0007',
    label: 'Drive',
    icon: Icons.explore_outlined,
    activeIcon: Icons.explore_rounded,
  ),

  /// Trip history — the drives recorded from real GPS during Focus Drive.
  trips(
    id: 'trips',
    label: 'Trips',
    icon: Icons.route_outlined,
    activeIcon: Icons.route_rounded,
  ),

  /// The drive-sounds home with the three assignable cue slots.
  sounds(
    id: '0006',
    label: 'Sounds',
    icon: Icons.graphic_eq_outlined,
    activeIcon: Icons.graphic_eq_rounded,
  ),

  /// The user's vehicle profile (VIN decode).
  car(
    id: 'vin_scan',
    label: 'Car',
    icon: Icons.directions_car_outlined,
    activeIcon: Icons.directions_car_filled_rounded,
  );

  const AppMainTab({
    required this.id,
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  /// The app_spec screen id this tab roots at.
  final String id;
  final String label;
  final IconData icon;
  final IconData activeIcon;

  /// The route name used to reach this root.
  String get route => '/$id';
}

/// The shared bottom tab bar for the four app roots.
///
/// Switching tabs replaces the whole stack with the target root, so the four
/// roots stay siblings and repeated tab taps can never pile screens up.
class AppMainTabBar extends StatelessWidget {
  const AppMainTabBar({super.key, required this.current});

  /// The tab whose screen is currently on screen.
  final AppMainTab current;

  void _select(BuildContext context, AppMainTab tab) {
    if (tab == current) return;
    Navigator.of(context).pushNamedAndRemoveUntil(tab.route, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomBar(
      currentIndex: current.index,
      onTap: (i) => _select(context, AppMainTab.values[i]),
      items: [
        for (final AppMainTab tab in AppMainTab.values)
          AppBottomBarItem(
            icon: tab.icon,
            activeIcon: tab.activeIcon,
            label: tab.label,
          ),
      ],
    );
  }
}
