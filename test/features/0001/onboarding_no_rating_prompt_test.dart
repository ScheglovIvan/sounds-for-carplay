import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drivana/core/router/app_router.dart';
import 'package:drivana/features/0001/0001_screen.dart';

/// App Store guideline 5.6.3 forbids asking for a rating before the user has
/// used the app, so the second onboarding step must carry no rating request:
/// no interactive stars, no "rate"/"rating" call to action. The testimonials
/// (and their decorative stars) are allowed to stay as static social proof.
void main() {
  /// Hosts [Screen_0001] with a stub route table so `_continue()` can be
  /// observed without building the real (Apphud-backed) paywall.
  Widget harness(List<String> pushed) {
    return MaterialApp(
      home: const Screen_0001(),
      onGenerateRoute: (RouteSettings settings) {
        pushed.add(AppRouter.idFromRouteName(settings.name) ?? '');
        return MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('next screen')),
        );
      },
    );
  }

  testWidgets('onboarding step 0001 shows no star-rating control',
      (WidgetTester tester) async {
    await tester.pumpWidget(harness(<String>[]));
    await tester.pump();

    // The interactive 5-star row was built from IconButtons; nothing on this
    // screen taps a star any more.
    expect(find.byType(IconButton), findsNothing);
    expect(find.byIcon(Icons.star_border_rounded), findsNothing);

    // Testimonial stars remain, but purely decorative — none of them sits in a
    // tap target.
    for (final Type tappable in <Type>[GestureDetector, InkWell]) {
      expect(
        find.ancestor(
          of: find.byIcon(Icons.star_rounded),
          matching: find.byType(tappable),
        ),
        findsNothing,
      );
    }
  });

  testWidgets('onboarding step 0001 has no rate/rating call to action',
      (WidgetTester tester) async {
    await tester.pumpWidget(harness(<String>[]));
    await tester.pump();

    final RegExp rating = RegExp(r'rat(e|ing)', caseSensitive: false);
    final Iterable<String> copy = tester
        .widgetList<Text>(find.byType(Text))
        .map((Text t) => t.data ?? '')
        .where((String s) => s.isNotEmpty);

    expect(copy, isNotEmpty);
    for (final String line in copy) {
      expect(rating.hasMatch(line), isFalse,
          reason: 'onboarding copy must not solicit a rating: "$line"');
    }
  });

  testWidgets('primary button is "Continue" and advances to screen 0002',
      (WidgetTester tester) async {
    final List<String> pushed = <String>[];
    await tester.pumpWidget(harness(pushed));
    await tester.pump();

    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(pushed, <String>['0002']);
  });
}
