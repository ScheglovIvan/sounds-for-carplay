import 'package:flutter/material.dart';

// Every screen id in app_spec.json gets a placeholder here. A later screen task
// OVERWRITES lib/features/<id>/<id>_screen.dart (same path + class name), so this
// router never needs editing when real screens land.
import 'package:drivana/features/splash/splash_screen.dart';
import 'package:drivana/features/0000/0000_screen.dart';
import 'package:drivana/features/0001/0001_screen.dart';
import 'package:drivana/features/0002/0002_screen.dart';
import 'package:drivana/features/paywall_special/paywall_special_screen.dart';
import 'package:drivana/features/0006/0006_screen.dart';
import 'package:drivana/features/0004/0004_screen.dart';
import 'package:drivana/features/0005/0005_screen.dart';
import 'package:drivana/features/home_arrival_sound/home_arrival_sound_screen.dart';
import 'package:drivana/features/0007/0007_screen.dart';
import 'package:drivana/features/0014/0014_screen.dart';
import 'package:drivana/features/vin_scan/vin_scan_screen.dart';
import 'package:drivana/features/0003/0003_screen.dart';
import 'package:drivana/features/0012/0012_screen.dart';
import 'package:drivana/features/0008/0008_screen.dart';
import 'package:drivana/features/0009/0009_screen.dart';
import 'package:drivana/features/0010/0010_screen.dart';
import 'package:drivana/features/connection_guide/connection_guide_screen.dart';
import 'package:drivana/features/trips/trips_screen.dart';
import 'package:drivana/features/safety_score/safety_score_screen.dart';
import 'package:drivana/features/break_reminders/break_reminders_screen.dart';

/// Central router for the whole app.
///
/// Resolves three route shapes to the SAME screen widget for each id:
///   * `/<id>`                        (in-app navigation)
///   * `/screen/<id>`                 (canonical web preview: `/#/screen/<id>`)
///   * `iosforge://screen/<id>`       (deep link; parsed from the incoming URI)
class AppRouter {
  AppRouter._();

  /// The first screen shown on launch.
  static const String initialRoute = '/splash';

  /// id -> builder for every screen in app_spec.json.
  static final Map<String, WidgetBuilder> screens = <String, WidgetBuilder>{
    'splash': (_) => const Screen_splash(),
    '0000': (_) => const Screen_0000(),
    '0001': (_) => const Screen_0001(),
    '0002': (_) => const Screen_0002(),
    'paywall_special': (_) => const Screen_paywall_special(),
    '0006': (_) => const Screen_0006(),
    '0004': (_) => const Screen_0004(),
    '0005': (_) => const Screen_0005(),
    'home_arrival_sound': (_) => const Screen_home_arrival_sound(),
    '0007': (_) => const Screen_0007(),
    '0014': (_) => const Screen_0014(),
    'vin_scan': (_) => const Screen_vin_scan(),
    '0003': (_) => const Screen_0003(),
    '0012': (_) => const Screen_0012(),
    '0008': (_) => const Screen_0008(),
    '0009': (_) => const Screen_0009(),
    '0010': (_) => const Screen_0010(),
    'connection_guide': (_) => const Screen_connection_guide(),
    // Trips tab root — real, GPS-recorded drive history.
    'trips': (_) => const Screen_trips(),
    // Drive Score, computed from the recorded trips.
    'safety_score': (_) => const Screen_safety_score(),
    // Break reminders for long drives.
    'break_reminders': (_) => const Screen_break_reminders(),
  };

  /// Extracts the target screen id from any supported route/URI string.
  static String? idFromRouteName(String? name) {
    if (name == null || name.isEmpty) return null;

    // The Flutter framework can hand us a raw URI (deep link) or a path.
    final Uri uri = Uri.parse(name);

    // Deep link: iosforge://screen/<id>  -> host="screen", path="/<id>".
    if (uri.scheme == 'iosforge') {
      final segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (uri.host == 'screen' && segs.isNotEmpty) return segs.last;
      if (segs.isNotEmpty) return segs.last;
      if (uri.host.isNotEmpty) return uri.host;
      return null;
    }

    final segments =
        uri.pathSegments.where((s) => s.isNotEmpty).toList(growable: false);
    if (segments.isEmpty) return null;

    // `/screen/<id>` canonical preview route.
    if (segments.length >= 2 && segments.first == 'screen') {
      return segments[1];
    }

    // `/<id>` direct route.
    return segments.last;
  }

  /// [MaterialApp.onGenerateRoute].
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final String? id = idFromRouteName(settings.name);
    final WidgetBuilder? builder = id == null ? null : screens[id];

    if (builder == null) {
      return _buildRoute(
        settings,
        (_) => _UnknownRouteScreen(routeName: settings.name),
      );
    }

    return _buildRoute(
      RouteSettings(name: '/$id', arguments: settings.arguments),
      builder,
    );
  }

  /// A single shared page transition used for every route: a soft fade paired
  /// with a short upward slide. Keeping it in the router (rather than per screen)
  /// gives the whole app one consistent, gentle motion language. The initial
  /// route is shown without animation by the framework, so standalone web
  /// previews still render their final frame immediately.
  static PageRouteBuilder<dynamic> _buildRoute(
    RouteSettings settings,
    WidgetBuilder builder,
  ) {
    return PageRouteBuilder<dynamic>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final Animation<double> eased = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: eased,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.035),
              end: Offset.zero,
            ).animate(eased),
            child: child,
          ),
        );
      },
    );
  }

  /// Navigate to a screen by its app_spec id (e.g. `AppRouter.go(context, '0006')`).
  static Future<T?> go<T>(BuildContext context, String id, {Object? arguments}) {
    return Navigator.of(context)
        .pushNamed<T>('/$id', arguments: arguments);
  }
}

class _UnknownRouteScreen extends StatelessWidget {
  const _UnknownRouteScreen({this.routeName});

  final String? routeName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No screen for route "${routeName ?? ''}"',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
    );
  }
}
