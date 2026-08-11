import 'package:flutter_test/flutter_test.dart';

import 'package:drivana/core/data/languages.dart';

void main() {
  group('Languages', () {
    test('ships exactly one language — English', () {
      // The app has no translation bundles yet, so it must offer English only
      // (App Store Guideline 2.3). Re-adding entries here without real .arb
      // translations would reintroduce the rejection.
      expect(Languages.all, hasLength(1));
      final AppLanguage only = Languages.all.single;
      expect(only.code, 'en');
      expect(only.nativeName, 'English');
      expect(only.englishName, 'English');
    });

    test('fallback is English', () {
      expect(Languages.fallback.code, 'en');
    });

    test('byCode returns English for a known and an unknown code', () {
      expect(Languages.byCode('en').code, 'en');
      // Any non-English (now unsupported) code resolves to the English fallback.
      expect(Languages.byCode('ar').code, 'en');
      expect(Languages.byCode('zz').code, 'en');
      expect(Languages.byCode(null).code, 'en');
    });

    test('English is left-to-right', () {
      expect(Languages.fallback.isRtl, isFalse);
    });
  });
}
