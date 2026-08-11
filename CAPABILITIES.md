# Capabilities & Limitations

**Drivana** — a calm driving companion. It reproduces the source app's real
behaviour using public iOS APIs only (no Apple paid entitlements, no private
APIs, no API keys). Where a feature needs something we cannot obtain, the closest
working implementation is shipped and the exact limitation is documented below
and surfaced honestly in the UI where that feature lives.

## Repositioning (Drivana) — what this pass changed
- The app is **Drivana**, not "Car Sounds & Dashboard" / "Sounds for CarPlay".
  The word "CarPlay" appears in **no** user-facing string, asset, config value,
  bundle name or Dart library name; the Dart package was renamed
  `carplay_sounds_clone` → `drivana`, which is also what gives the iOS build its
  `CFBundleDisplayName` (there is no checked-in `ios/` directory — the build
  pipeline re-runs `flutter create`, which derives the display name from the
  pubspec `name`).
- Bottom tab bar: **Drive · Trips · Sounds · Car**, owned by one component
  (`AppMainTabBar` / `AppMainTab` in `lib/ui/components/app_main_tabs.dart`) that
  every root renders, so labels, icons and order live in a single place.
- **Screen ids 0007 and 0014 were swapped to match `app_spec.json` and the
  ground-truth screenshot `screens/0007.png`.** `0007` is now the Focus Drive
  home (the Drive tab root: preview tiles, permissions, Setup Guide row and the
  Start Focus Drive CTA) and `0014` is the immersive live board. The previous
  build had these reversed, so `/#/screen/0007` rendered the landscape board
  instead of the captured portrait tab screen.
- `trips` (`/trips`) is now a **real, GPS-recorded drive history** — see
  "Trips, Drive Score and Break Reminders" below. `safety_score`
  (`/safety_score`) and `break_reminders` (`/break_reminders`) landed with it, so
  every screen id in `app_spec.json` now has a widget and a route.
- Renamed headings: "Driving Mode" → **Focus Drive**, "Your Sounds" →
  **Drive Sounds**, "VIN Scan"/"VIN Lookup" → **My Car**, "How to Activate" →
  **Setup Guide**.
- The three sound slots keep their persistence keys (`connection`,
  `disconnection`, `home_arrival`) and their audio engine untouched; only the
  framing changed to **Departure cue** / **Arrival cue** / **Home cue**.
- The Setup Guide's third illustration (`assets/media/guide_step_3.png`) was
  **deleted**: it was a screenshot of Apple's Shortcuts trigger list with the
  word "CarPlay" rendered into the image. That step now shows a clean gradient
  panel with a glyph, and its copy describes the car-connection trigger without
  naming it. The other four guide screenshots are unbranded and were kept.
- `kPrivacyPolicyUrl` (`lib/core/data/legal_links.dart`) points at Drivana's
  live, hosted Privacy Policy page.

## Permission priming (App Store 5.1.1(iv)) — COMPLIANT
- Every custom screen shown BEFORE a system permission dialog explains only WHY
  the access helps. **No priming button tells the user how to answer the system
  dialog** — the labels are neutral ("Continue"), never "Allow" or "Enable".
  This covers the Focus Drive home's "Share your location" and "Turn on alerts"
  cards, the live map's location prompt, and the shared
  `requestPermission()` sheet (whose parameter is now `continueLabel`, defaulting
  to "Continue").
- The real iOS system dialogs are unchanged and are still what actually grants
  access.
- **Notifications are a real permission now, not a local flag.** The "Turn on
  alerts" card calls `NotificationService.request()`
  (`lib/core/services/notification_service.dart`), which triggers the actual iOS
  `UNUserNotificationCenter` authorization prompt via `permission_handler`
  (`Permission.notification`) and mirrors the OS answer into
  `AppState.notificationsEnabled`. On a permanent denial — where iOS never shows
  the prompt again — it opens the app's Settings page instead, which is the only
  place the decision can still change. The state is re-read on entering the Drive
  tab so a change made in iOS Settings is picked up. iOS requires **no**
  Info.plist usage-description key for notifications, so `ios_permissions.json`
  is unchanged by this.

## Live Apple Maps (Focus Drive) — REAL
- Package: `apple_maps_flutter` (native MapKit, no API key).
- Location: `geolocator` for the real GPS fix, `permission_handler` for the real
  iOS `When In Use` dialog (`NSLocationWhenInUseUsageDescription`).
- Behaviour: on first use we trigger the real system permission dialog; once
  granted the map centres on the user's actual position with a "my location" dot.
  It is a normal interactive map — pinch-zoom, pan and rotate are enabled — and it
  **follows** the user: `LocationService.positionStream()` (geolocator
  `getPositionStream`) streams live GPS fixes and each new fix moves the camera
  via `AppleMapController.moveCamera(...)` so the map stays centred as you drive.
- Never hangs: a fix request is time-limited (10s). The OS's last known position
  paints the map immediately when there is one, then a fresh fix refines it. If
  neither can be obtained (indoors, underground, no SIM, Location Services off)
  the tile shows a short "Couldn't get your location" state with a **Retry**
  action — never an endless spinner.
- Limitation: the native MapKit view only renders on a real iOS device/simulator.
  On the web preview and other platforms the plugin has no view, so those builds
  show an honest "Live Apple Maps runs on device" note instead of a fake map.

## Live status bar (time / battery / network) — REAL
- Time: `DateTime.now()` on a one-second `Timer`, formatted with `intl`.
- Battery level + charging state: `battery_plus`.
- Network reachability (Wi‑Fi / cellular / offline): `connectivity_plus`.
- No value in the status bar is hardcoded.

## Focus Drive pages — the glance board and now playing
- The rail pages between exactly two surfaces: the glance board (live Apple map,
  weather, and the system now-playing tile) and the full now-playing page.
- The former home app-grid page and the in-app phone dialer page were
  **removed**: a launcher grid and a keypad are generic iOS-shell imitations
  rather than driving features, so Focus Drive now only shows what it actually
  does itself. `AppLauncher` remains for the Apple Music hand-off below.

## Apple Music now-playing / control — REAL (mirrors the system player)
The app does **not** stream, host or manage Apple Music content itself, and it
never plays its own audio on this surface. It reproduces exactly what the source
app does:

1. **Open** — the music button opens the real Apple Music app via the public
   `music://` scheme with `url_launcher` (`AppleMusicService.openAppleMusic`),
   falling back to `https://music.apple.com/` and, if neither can be opened,
   saying so instead of failing silently.
2. **Play there** — the user starts playback in Apple Music.
3. **Reflect** — the Focus Drive board tile and the music page bind to the
   **real system now-playing item** (title, artist, album, artwork, duration,
   elapsed time) read from `MPMusicPlayerController.systemMusicPlayer` through
   our own `packages/system_music/` plugin. Authorization is the real iOS Apple
   Music / Media Library dialog via `permission_handler`
   (`Permission.mediaLibrary`, backed by `NSAppleMusicUsageDescription`),
   requested when the Focus Drive music surface opens. Nothing is mocked: with
   nothing playing, the tile simply offers to open Apple Music.
   - The **position is optional by design**. `currentPlaybackTime` (and
     sometimes `playbackDuration`) is **NaN** in perfectly normal states —
     before the system player has been prepared to play in this process, even
     while an item is loaded and `playbackState` is playing. The Swift converts
     no MediaPlayer `Double` without an `isFinite` check first (Swift traps on
     `Int(NaN)`), and reports the value as **unknown** rather than as `0`. Dart
     then renders the track and its transport controls with no progress figure.
     This is why the third-party `nowplaying` package was dropped: it converted
     that NaN with an unguarded `Int(...)` and crashed the app on entering
     Focus Drive.
4. **Control** — play / pause / next / previous drive
   `MPMusicPlayerController.systemMusicPlayer`, i.e. the same playback the Music
   app owns.

- `MPMusicPlayerController` has no pub package, so both the read and the control
  side ship as a **local plugin package** in this repo: `packages/system_music/`
  (Swift class `SystemMusicPlugin`, method channel `system_music`), referenced
  from `pubspec.yaml` by path. Dart polls its `nowPlaying` method once a second
  while the surface is up; artwork bytes only cross the channel when the item
  actually changes. It deliberately is NOT under `ios/Runner/`: the build
  pipeline re-runs `flutter create --platforms=ios,android .`, which would erase
  anything hand-registered in `AppDelegate`/`project.pbxproj`, whereas a plugin
  package is re-registered automatically.
- Honest degradation: `SystemMusic.isAvailable()` probes the native side for
  real. If the plugin is unreachable (non-iOS build, registration failed) the
  transport buttons are **hidden entirely** and the UI says playback is
  controlled from Apple Music — no button that does nothing.
- Limitation: full Apple Music **catalog** playback inside this app would need a
  MusicKit developer token plus an active subscription, which we do not have —
  and the source app doesn't do that either. Opening Apple Music and
  reflecting/controlling the system player is the real behaviour, not a
  substitute for it.

## My Car / VIN decode — REAL request, closest-available backend
- The **Car** tab (screen id `vin_scan`, kept so existing deep links still
  resolve) is a real lookup: the driver types their vehicle's 17-character VIN,
  taps **Decode VIN**, and the app performs a REAL HTTPS request (via the `http`
  package), then pushes a separate results screen showing the genuine vehicle
  fields returned — including Make, Model, Model year, Trim, Engine model and
  Body class.
- Backend: `GET https://vpic.nhtsa.dot.gov/api/vehicles/DecodeVinValues/<VIN>?format=json`
  — NHTSA vPIC, public, no API key, no auth, HTTPS. `Results[0]` (a flat JSON
  object) is parsed and only fields with a real, non-empty value are shown
  (vPIC returns empty strings / "Not Applicable" for unknowns, which are
  filtered out). No vehicle value is ever hardcoded and no fallback data is
  invented on failure.
- Limitation: the original app's exact VIN backend was NOT observed — the VIN
  screen was never crawled and no VIN network traffic was captured, so exact
  replication is impossible. NHTSA vPIC is used as the closest real, working,
  key-less implementation.
- **No camera scan.** `app_spec.json` describes a camera viewfinder for capturing
  the VIN, but this build ships manual entry only: the app bundles no camera
  package and requests no camera permission, so there is deliberately **no**
  `NSCameraUsageDescription` key in `ios_permissions.json` (a permission
  requested without its key crashes on device). The screen says plainly that the
  VIN is typed in and where to find it on the vehicle, rather than showing a
  viewfinder that cannot capture anything. Adding a real scanner would mean
  adding a camera/ML text-recognition dependency and the matching plist key.
- Errors are handled without crashes: empty / invalid (non-17-char) VINs show an
  inline validation message and do not navigate; offline (`SocketException`),
  timeout, non-200 status and vPIC `ErrorCode != 0` / empty results all show a
  friendly message with a **Try again** affordance.

## Subscriptions / In-App Purchase (Apphud) — REAL (StoreKit sandbox)
- Purchases go through **Apphud** (`apphud`), never a local flag. `main()` calls
  `Apphud.start(apiKey: sdk_key)` with the key from `apphud_config.json` (guarded
  in a try/catch: a no-op on web/unsupported platforms or an empty key, and it
  never throws).
- The paywalls are **fully driven by the Apphud dashboard**. `ApphudService.loadPaywall()`
  reads `Apphud.placements()`, picks the `main_drivana` placement
  (from `apphud_config.json`) and renders one plan card per product it returns.
  Product ids, titles, prices and billing periods are all read off the live
  Apphud/StoreKit product at runtime (`SubscriptionProduct.fromApphud`) — **the
  app ships no product catalog and hardcodes no price or product id**, so a
  product added later in the Apphud dashboard appears without an app update.
- **The displayed price is always the price the store will charge.** Products are
  re-fetched from the SDK every time a paywall is shown and again whenever the
  app returns to the foreground (`ApphudService.refreshProducts()` plus a
  lifecycle observer on each paywall) — never reused from whatever was cached at
  SDK start, so a storefront/territory change cannot leave a stale price on
  screen. A product with no real store price attached is not rendered at all:
  the paywall shows its loading state instead. **No placeholder or hardcoded
  number is ever displayed.**
  - The "% OFF" badge, the per-week framing and the special-offer wall's
    struck-through comparison price are all derived from that **same freshly
    loaded** product set, so they cannot disagree with the headline price.
  - The standard paywall pre-selects the **yearly** plan — resolved from the
    live products' real billing periods, so the plan carrying the savings badge
    is the plan named in the CTA. All plans stay visible and selectable.
- Buy with `Apphud.purchase(product: ...)` (the live product object), restore with
  `Apphud.restorePurchases()`. Every load state is handled explicitly and the
  paywall is never blank: **loading** (spinner), **ready**, **no products
  returned** (clear message + Try again), **store unavailable on this platform**
  (honest note, CTA disabled), **error** (message + Try again). A user-cancelled
  purchase closes quietly with no error; a failure shows a retry message.
- Limitation: real App Store IAP would additionally require App Store Connect
  products, a paid Apple Developer account and app signing. Apphud auto-detects
  the **StoreKit sandbox** vs production, so purchases are testable in the sandbox
  **without** a live App Store link; there is no live App Store link yet.

## Free vs PRO gating — single source of truth
- Entitlement is **only** ever `await Apphud.hasPremiumAccess()`. There is no
  local bool, no persisted grant and no fake entitlement: `AppState.isPro` is an
  in-memory mirror that Apphud writes into, and any entitlement stored by an
  earlier build is purged at launch.
- It is re-checked **at app start** (`main()` / `AppBootstrap`), **on every
  resume** (`didChangeAppLifecycleState` in `main.dart`, so a subscription bought,
  cancelled or expired outside the app is picked up), and **after every purchase
  and restore**. Because the gates listen to `AppState.isPro`, unlocked content
  appears immediately after a purchase with **no app restart**.
- Gated exactly per `app_spec.json` `monetization.paywalls`:
  - **Premium sounds** — locked rows in the sound picker show a lock/PRO badge and
    tapping one opens the paywall.
  - **Premium board upgrade (Focus Drive live)** — the Drive tab's launch card
    carries a PRO lock badge for free users and its CTA opens the paywall.
- Free features stay fully usable without a subscription — the free sound subset,
  assigning a cue to a slot, unlimited previews, Language / Theme / Units, the
  Drive tab's live previews and permissions, the Setup Guide and the My Car VIN
  decode. The app is never blocked as a whole.

## Trips, Drive Score and Break Reminders — REAL, with one documented limit
Recorded drives are the data behind three screens (`trips`, `safety_score`,
`break_reminders`). **Nothing on them is seeded, mocked or demo data** — a fresh
install shows empty states until the user actually drives.

**What is real**
- `TripRecorder` (`lib/core/services/trip_recorder.dart`) starts when Focus Drive
  (`0014`) gets a real location grant and stops when the board closes.
- Distance is summed from consecutive **real CoreLocation fixes** with
  `Geolocator.distanceBetween`; implausible jumps (a re-acquired fix after a
  tunnel) are discarded so the total stays honest.
- Speed is the fix's own `speed` value from CoreLocation. When CoreLocation
  reports no valid speed we show nothing rather than a zero.
- Harsh braking / hard acceleration are detected from the **longitudinal
  acceleration between two real fixes** (Δspeed / Δt), thresholded at −3.0 m/s²
  and +2.6 m/s², with a sample-spacing window, a minimum road speed and a
  per-kind cooldown so noise and car-park creeping never score against the
  driver.
- The Drive Score gauge, the event counts, the 7-day trend and the recent-event
  list are all **computed** from those stored trips. A day with no drive draws an
  empty column instead of an invented score.
- The trip-detail route map is a native Apple Map (`apple_maps_flutter`, MapKit,
  no API key) drawing the trip's **own stored coordinates** as a polyline.
- Trips are persisted on device with `shared_preferences` (key `trips.v1`), route
  points down-sampled to 300 per trip and the history capped at 50 drives.
- Drives shorter than 60 s / 150 m are **discarded, not saved** — opening and
  closing the board must not litter the history with a zero-distance "drive".
- The Focus Drive status bar's trip readout (distance · elapsed) is bound to the
  recorder and simply disappears when nothing is recording.

**Limitations and the fallback shipped instead**
- **CoreMotion accelerometer:** `app_spec.json` suggests `sensors_plus` for harsh
  event detection. Drivana derives longitudinal acceleration from CoreLocation
  speed deltas instead, which needs no extra dependency and no
  `NSMotionUsageDescription`. It is real device motion, but sampled at GPS rate,
  so it catches sustained harsh braking/acceleration rather than very brief
  jolts. If a motion feed is added later, `TripRecorder._detectEvent` is the one
  place to change.
- **Background recording:** the app ships **no Always-on location entitlement and
  no background-location mode**, so recording runs while the Focus Drive board is
  on screen — which is exactly where the app's driving board lives. Trips are not
  recorded when the app is backgrounded.
- **Break reminders fire in-app, not as background banners.** No local
  notification scheduler is bundled, so the nudge is raised on the Focus Drive
  board (with `HapticFeedback.heavyImpact`) when the configured minutes of real
  driving have elapsed. The enable switch still triggers the **actual iOS
  notification authorization dialog** through `permission_handler` and only
  latches on if the OS grants it — it is never a local-only flag. The Break
  Reminders screen states this limit in its own UI ("Reminders run while Focus
  Drive is on screen — that is where the drive timer counts").

**Free vs PRO** — free users see the most recent 3 drives and the this-week Drive
Score window; the full history and the all-time window are PRO, gated through the
same `AppState.isPro` / Apphud source of truth as everything else.

## Attribution (Tenjin) — REAL, measurement only
- Packages: `tenjin_plugin` + `app_tracking_transparency`. SDK key from
  `attribution_config.json` (`AttributionService._sdkKey`, re-synced with the
  config file this pass — the key rotates per app, and a stale one silently
  reports to the wrong Tenjin account). All of it is guarded in try/catch and
  no-ops on an empty key or an unsupported platform, so it can never crash the
  app.
- Order (`AttributionService.start()`, run from a post-first-frame callback in
  `main.dart` because Apple requires the app to be foregrounded and visible
  before the ATT prompt may appear — never pre-`runApp`):
  1. `AppTrackingTransparency.requestTrackingAuthorization()` — the real iOS ATT
     dialog (`NSUserTrackingUsageDescription`, in `ios_permissions.json`).
  2. `TenjinSDK.instance.initialize(sdkKey: ...)`.
  3. `optIn()` when ATT is authorized, otherwise `optOut()`.
  4. `TenjinSDK.instance.connect()`.
  5. `AppTrackingTransparency.getAdvertisingIdentifier()` → when non-empty (and
     not the all-zero placeholder) `Apphud.setAdvertisingIdentifier(idfa)`, so a
     purchase ties back to the campaign that drove the install.
  6. `Apphud.collectSearchAdsAttribution()` (Apple Search Ads).
- **No ad network, campaign, creative or tracking link is named anywhere in the
  app** — traffic sources are connected in the Tenjin dashboard. This is
  measurement only: the app contains **no ad SDK and no ad units**.

## Theme (Light / Dark / System) — REAL
- Real light and dark `ThemeData`, an app-wide `ThemeMode` the root `MaterialApp`
  listens to, and a working Appearance screen (feature `0009`) that persists the
  choice with `shared_preferences` so it survives restart.
- The design-system tokens (`AppColors.*`) resolve against the active brightness,
  so every screen is fully readable in both Light and Dark.

Every permission listed above has its matching Info.plist usage-description in
`ios_permissions.json`, which the iOS build injects into Info.plist.
