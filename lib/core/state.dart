/// Barrel for the app's shared state & persistence layer.
///
/// Screen tasks can `import '../../core/state.dart';` to get the reactive
/// [AppState] notifiers, the sound catalog + models, subscription/paywall data,
/// settings enums, the language list and the Adapty entitlement stand-in.
library;

export 'app_state.dart';
export 'data/languages.dart';
export 'data/sound_catalog.dart';
export 'models/sound.dart';
export 'models/subscription.dart';
export 'models/user_settings.dart';
export 'services/entitlement_service.dart';
export 'services/preferences_store.dart';
export 'services/purchase_flow.dart';
export 'services/sound_preview_player.dart';
