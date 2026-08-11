/// Single source of truth for the app's legal links.
///
/// Referenced from every site that shows Terms / Privacy (the paywalls and the
/// Settings screen) so the URLs are never hardcoded in more than one place.
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Privacy Policy shown on the subscription screens and in Settings.
///
/// NOTE: this is Drivana's live, hosted Privacy Policy page.
const String kPrivacyPolicyUrl =
    'https://scheglovivan.github.io/drivana/privacy';

/// Terms of Use — Apple's standard EULA for auto-renewing subscriptions.
const String kTermsOfUseUrl =
    'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';

/// Open a legal [url] in the external browser, surfacing a brief SnackBar on
/// failure rather than crashing. Shared by every Terms / Privacy tap target so
/// the launch + error handling lives in exactly one place.
Future<void> openLegalLink(BuildContext context, String url) async {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  bool ok = false;
  try {
    ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {
    ok = false;
  }
  if (!ok) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Could not open the link right now.')),
      );
  }
}
