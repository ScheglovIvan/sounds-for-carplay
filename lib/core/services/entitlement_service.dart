import '../app_state.dart';
import '../models/sound.dart';
import '../models/subscription.dart';
import 'apphud_service.dart';

/// Result of a purchase / restore attempt.
enum EntitlementResult { success, cancelled, failed, nothingToRestore }

/// Resolves and gates the PRO entitlement through the REAL store (Apphud).
///
/// Every buy / restore / unlock goes through [ApphudService] — there is no
/// local "succeeds anyway" stand-in and no local flag: PRO is granted only when
/// Apphud reports premium access (`Apphud.hasPremiumAccess()`), which is
/// re-checked at launch, on app resume and after every purchase/restore, and is
/// never persisted to disk. Apphud auto-detects the StoreKit sandbox, so this is
/// fully testable without a live App Store build — see `apphud_config.json` /
/// `CAPABILITIES.md`.
///
/// On a platform where Apphud can't run (web/desktop preview) purchases are
/// unavailable rather than faked, so previews never grant a fake entitlement.
class EntitlementService {
  EntitlementService._();

  static final EntitlementService instance = EntitlementService._();

  /// Whether a premium [sound] is currently locked for this user.
  bool isSoundLocked(Sound sound) => sound.isPremium && !AppState.isPro.value;

  /// Whether any premium content/feature is locked right now.
  bool get isLocked => !AppState.isPro.value;

  /// Buy [product] against the live store via [ApphudService]. PRO unlocks only
  /// when Apphud confirms premium access. Returns [failed] (with no local grant)
  /// when Apphud isn't available on this platform.
  Future<EntitlementResult> purchase(SubscriptionProduct product) async {
    if (!ApphudService.isStarted) return EntitlementResult.failed;
    return ApphudService.purchase(product);
  }

  /// Restore a previous purchase through Apphud and unlock PRO when premium
  /// access is found.
  Future<EntitlementResult> restore() async {
    if (!ApphudService.isStarted) return EntitlementResult.nothingToRestore;
    return ApphudService.restore();
  }
}
