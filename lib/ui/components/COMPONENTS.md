# Design System — Shared Components

Every screen composes ONLY from these widgets. They consume the divergent
`design_tokens` exclusively (via `lib/ui/theme/app_theme.dart` — `AppColors`,
`AppRadii`, `AppDimens`, `AppGradients`, `AppStyleTokens`). Do **not** hardcode
colors, fonts, gradients, or corner radii in a screen; if a screen needs a look
that isn't here, extend a component rather than inlining styles.

Import everything in one line:

```dart
import 'package:drivana/ui/components/components.dart';
```

This barrel also re-exports the theme tokens, so `AppColors`, `AppGradients`,
etc. are available without a second import.

## Conventions

- **Icons:** rounded Material variants (`Icons.*_rounded`) throughout — a
  deliberately different icon style from the source app. Keep using rounded
  variants when picking icons in screens.
- **Fonts:** inherited from the theme (`GoogleFonts` Poppins). Never set a
  `fontFamily` on a screen.
- **Corners:** `AppRadii.sm/md/lg/pill` (12 / 24 / 30 / 42).
- **Button height:** `AppDimens.buttonHeight` (54); page gutter
  `AppDimens.gutter` (15).

## Components

| Widget | Purpose |
| --- | --- |
| `AppScaffold` | Page shell: token background, optional top/bottom bar, full-bleed background layer. |
| `AppTopBar` | Nav bar with back/menu leading + actions (implements `PreferredSizeWidget`). |
| `AppBottomBar` | Main tab bar (`AppBottomBarItem` list). |
| `AppMainTabBar` | The four app roots (Drive · Trips · Sounds · Car) — use this on every tab root. |
| `AppButton` | Primary/secondary action — `gradient` / `white` / `outlined` / `ghost` variants. |
| `AppProBadge` | GET PRO / Go Premium gradient badge. |
| `AppBadge` | Small tag pill (discount, PRO, FREE, status). |
| `AppCard` | Base surface container; `selected` adds a primary outline. |
| `AppTextField` | Pill search / text field. |
| `AppChip` / `AppChipBar` | Category filter chips. |
| `AppListTile` | Settings/menu/drawer row. |
| `AppSlotCard` | A drive cue slot (Departure / Arrival / Home). |
| `AppSoundRow` | Sound-library row: preview play, title, PRO tag, radio/lock. |
| `AppSectionHeader` | Section title + optional trailing action. |
| `AppBanner` | Inline warning/info notice. |
| `AppEmptyState` | Centered zero-result / error placeholder. |

See `manifest.json` for the full prop list and per-widget usage notes.
