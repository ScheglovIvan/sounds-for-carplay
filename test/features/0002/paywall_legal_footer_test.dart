import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drivana/features/0002/0002_screen.dart';

void main() {
  testWidgets(
    'paywall legal footer exposes tappable Terms and Privacy targets',
    (WidgetTester tester) async {
      // Apphud is never started in a widget test, so the paywall loads its
      // "unavailable" state (no plugin calls) and still renders the footer.
      await tester.pumpWidget(const MaterialApp(home: Screen_0002()));
      await tester.pump();

      final Finder terms = find.text('Terms');
      final Finder privacy = find.text('Privacy');
      expect(terms, findsOneWidget);
      expect(privacy, findsOneWidget);

      // Each label must sit inside a tap target (a GestureDetector wired to
      // open the corresponding URL) — the old footer used plain, dead Text.
      expect(
        find.ancestor(of: terms, matching: find.byType(GestureDetector)),
        findsOneWidget,
      );
      expect(
        find.ancestor(of: privacy, matching: find.byType(GestureDetector)),
        findsOneWidget,
      );
    },
  );
}
