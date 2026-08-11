import 'dart:async';

import 'package:flutter/material.dart';

import 'core/app_state.dart';
import 'core/bootstrap/app_bootstrap.dart';
import 'core/data/languages.dart';
import 'core/router/app_router.dart';
import 'core/services/apphud_service.dart';
import 'core/services/attribution_service.dart';
import 'core/services/break_reminder_service.dart';
import 'core/services/trip_store.dart';
import 'ui/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Hydrate persisted state (theme, slot selections, prefs) before the first
  // frame so the app opens in the user's saved configuration. The PRO
  // entitlement is deliberately NOT persisted — Apphud is its only source.
  await AppState.load();
  // Recorded drive history + break-reminder settings share the same store, so
  // the Trips / Drive Score tabs open with the user's real data already in hand.
  await TripStore.instance.load();
  BreakReminderService.instance.load();
  // Start Apphud before the first frame (guarded internally: a no-op on
  // web/unsupported platforms or an empty key, and never throws). Then refresh
  // the entitlement so a returning subscriber opens already unlocked.
  await ApphudService.start();
  unawaited(ApphudService.refreshPremium());
  // Launch initialization the splash screen also awaits.
  unawaited(AppBootstrap.initialize());
  runApp(const DrivanaApp());
}

class DrivanaApp extends StatefulWidget {
  const DrivanaApp({super.key});

  @override
  State<DrivanaApp> createState() => _DrivanaAppState();
}

class _DrivanaAppState extends State<DrivanaApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Apple requires the app to be foregrounded and visible before the ATT
    // dialog may be shown, so attribution (ATT -> Tenjin -> IDFA -> Apphud)
    // starts once the first frame is on screen — never pre-runApp. Doing it
    // here rather than on the splash also covers deep-link entry points.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(AttributionService.start());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Re-read the entitlement from Apphud whenever the app comes back to the
  /// foreground, so a subscription bought, cancelled or expired outside the app
  /// (App Store settings, another device) is reflected right away.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ApphudService.refreshPremium());
      // Re-fetch the store products too: a storefront/territory change while
      // the app was backgrounded moves every product to a different price
      // tier, and a paywall must never show a price the store won't charge.
      unawaited(ApphudService.refreshProducts());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppState.themeMode,
      builder: (context, mode, _) {
        // The Language setting drives the app locale and, for RTL scripts such
        // as Arabic, mirrors the whole UI via a top-level [Directionality].
        return ValueListenableBuilder<AppLanguage>(
          valueListenable: AppState.language,
          builder: (context, language, _) {
            return MaterialApp(
              title: 'Drivana',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: mode,
              locale: language.locale,
              supportedLocales: [
                for (final l in Languages.all) l.locale,
              ],
              // Preview/build stays on Flutter's default localization
              // delegates; the selected language is applied here through the
              // app locale and directionality rather than translated bundles.
              builder: (context, child) {
                // Keep the design-system tokens (AppColors.*) in step with the
                // resolved brightness so every screen — including ones that read
                // the semantic tokens directly — repaints for Light/Dark. This
                // resolves ThemeMode.system through the active [Theme].
                AppColors.brightness = Theme.of(context).brightness;
                return Directionality(
                  textDirection:
                      language.isRtl ? TextDirection.rtl : TextDirection.ltr,
                  child: child ?? const SizedBox.shrink(),
                );
              },
              initialRoute: AppRouter.initialRoute,
              onGenerateRoute: AppRouter.onGenerateRoute,
            );
          },
        );
      },
    );
  }
}
