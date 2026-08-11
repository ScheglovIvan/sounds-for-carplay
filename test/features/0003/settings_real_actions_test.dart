import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'package:drivana/core/data/legal_links.dart';
import 'package:drivana/features/0003/0003_screen.dart';
import 'package:drivana/features/0012/0012_screen.dart';

/// Records every URL the app hands to `launchUrl`, so the tests can assert the
/// previously-dead Support / Billing rows now perform a real external launch
/// instead of only popping a toast (App Store Guideline 2.1).
class _FakeUrlLauncher extends UrlLauncherPlatform
    with MockPlatformInterfaceMixin {
  final List<String> launched = <String>[];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<void> closeWebView() async {}

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add(url);
    return true;
  }

  @override
  Future<bool> launch(
    String url, {
    required bool useSafariVC,
    required bool useWebView,
    required bool enableJavaScript,
    required bool enableDomStorage,
    required bool universalLinksOnly,
    required Map<String, String> headers,
    String? webOnlyWindowName,
  }) async {
    launched.add(url);
    return true;
  }
}

void main() {
  late _FakeUrlLauncher launcher;
  bool shareInvoked = false;
  Object? shareArgs;

  const MethodChannel shareChannel =
      MethodChannel('dev.fluttercommunity.plus/share');

  setUp(() {
    launcher = _FakeUrlLauncher();
    UrlLauncherPlatform.instance = launcher;
    shareInvoked = false;
    shareArgs = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(shareChannel, (MethodCall call) async {
      shareInvoked = true;
      shareArgs = call.arguments;
      // A valid ShareResultStatus raw value so share_plus can parse the result.
      return 'dev.fluttercommunity.plus/share/unavailable';
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(shareChannel, null);
  });

  // Toast strings the four rows used to show before they did anything real.
  // If any of these ever appears again, a row has regressed to a dead stub.
  const List<String> deadToasts = <String>[
    'Opening your mail app to contact us…',
    'Preparing a link to share…',
    'Opening the billing terms…',
  ];

  void expectNoDeadToasts() {
    for (final String toast in deadToasts) {
      expect(find.text(toast), findsNothing, reason: 'dead toast "$toast"');
    }
  }

  Future<void> tapRow(WidgetTester tester, String title) async {
    final Finder row = find.text(title);
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Menu (0003) Support rows launch mail / review and open the share sheet',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Screen_0003()));
      await tester.pumpAndSettle();

      // Get in touch -> system mail composer.
      await tapRow(tester, 'Get in touch');
      expect(
        launcher.launched.any((String u) => u.startsWith('mailto:') &&
            u.contains('vektor9966@gmail.com') &&
            u.contains('Drivana')),
        isTrue,
        reason: 'contact must open the mail composer via launchUrl',
      );

      // Leave a review -> the App Store write-review deep link (NOT screen 0001).
      await tapRow(tester, 'Leave a review');
      expect(
        launcher.launched
            .contains('https://apps.apple.com/app/id6793113392?action=write-review'),
        isTrue,
        reason: 'review must open the App Store review page via launchUrl',
      );

      // Tell a friend -> the real system share sheet (share_plus channel).
      await tapRow(tester, 'Tell a friend');
      expect(shareInvoked, isTrue,
          reason: 'share must open the system share sheet');
      expect(shareArgs.toString(),
          contains('https://apps.apple.com/app/id6793113392'));

      expectNoDeadToasts();
    },
  );

  testWidgets(
    'Membership (0012) Billing terms opens the shared Terms of Use link',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Screen_0012()));
      await tester.pumpAndSettle();

      await tapRow(tester, 'Billing terms');
      expect(
        launcher.launched.contains(kTermsOfUseUrl),
        isTrue,
        reason: 'billing terms must reuse openLegalLink(kTermsOfUseUrl)',
      );

      expectNoDeadToasts();
    },
  );
}
