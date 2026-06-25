# CLAUDE.md — FieldTaxa

This file provides guidance to Claude Code when working in this repository.

## Project Overview

**FieldTaxa** is a Flutter app (iOS + Android) for capturing, classifying, and tracking field observations of fauna, flora, and other taxa. It supports a hierarchical, fully editable taxonomy tree; multi-sighting logging per item; GPS / Swiss LV95 coordinate display; a Swisstopo WMTS map overlay; and a Search screen with category + date-range filters.

The Flutter project lives in `./fieldtaxa/`. The design reference (interactive HTML prototype + spec README) is in `./Requirements-Design/design_handoff_fieldtaxa/`. The user manual is in `./Specifications-Documentation/UserManual.md`.

**Current version:** `1.0.0+1` (main branch)

---

## Key Reference Documents

| File | Purpose |
|---|---|
| `Requirements-Design/design_handoff_fieldtaxa/README.md` | Full design spec: color tokens, typography, screen layouts, data model, navigation, state management structure |
| `Requirements-Design/design_handoff_fieldtaxa/FieldTaxa Reference.html` | Interactive HTML prototype — open in browser as visual reference |
| `Specifications-Documentation/UserManual.md` | End-user manual |
| `fieldtaxa/pubspec.yaml` | Dependencies and version |

---

## Flutter Project Commands

All commands run from inside `./fieldtaxa/`:

```bash
cd fieldtaxa

flutter pub get
flutter gen-l10n        # run after any .arb edit
flutter analyze --no-pub
dart format .
flutter run
flutter test
flutter build ios --release
flutter build apk --release
```

### Version bump
Increment `version` in `pubspec.yaml` manually (format: `<semver>+<build>`, e.g. `1.0.1+2`). The About screen reads the version at runtime via `package_info_plus` (not yet wired — currently hardcoded in `about_screen.dart`).

---

## Architecture

### Tech Stack
- **State management:** `flutter_riverpod` ^2.6.1 — `StateNotifier` pattern throughout
- **Routing:** `go_router` ^15.1.2 — `ShellRoute` for persistent bottom nav
- **Local storage:** `sqflite` ^2.4.1 — single `DatabaseHelper.instance` singleton
- **Settings:** `shared_preferences` ^2.3.4
- **Typography:** `google_fonts` ^6.2.1 — Plus Jakarta Sans (`jakartaStyle()`) + Newsreader (`newsreaderStyle()`)
- **Maps:** `cached_network_image` + Swisstopo WMTS tiles (`https://wmts.geo.admin.ch/1.0.0/ch.swisstopo.pixelkarte-farbe/default/current/3857/{z}/{x}/{y}.jpeg`)
- **Camera / media:** `image_picker` ^1.1.2
- **Location:** `geolocator` ^13.0.4 — WGS84; converted to Swiss LV95 via `wgsToLV95()` in `core/utils/coords.dart`
- **URLs:** `url_launcher` ^6.3.1

### Navigation Routes

```
/ (Gallery)            ← ShellRoute (bottom nav)
/category/:name        ← Category drill-down
/search                ← Search
/taxonomy              ← Taxonomy tree
/taxonomy/observations/:nodeId  ← Taxon Observations
/settings              ← Settings
/settings/about        ← About
/capture               ← Camera (standalone, no bottom nav)
/classify/:draftId     ← Classify (standalone, extra: {filePath, tags})
/viewer/:itemId        ← Photo Viewer (pushed as overlay)
```

### Bottom Navigation (ShellScaffold)
Five items: Gallery · Search · Capture FAB (54dp circle, raised 12px) · Taxonomy · Settings. No bottom nav on Capture, Classify, or Photo Viewer.

### Design Tokens
Defined in `lib/core/theme/app_theme.dart` as `abstract final class AppColors` and a `BuildContext` extension (`AppThemeX`). Always use theme tokens — never hardcode colours.

Key tokens:
- `appBg` → `#EEEEE5` / `#12140D`
- `appPrimary` → `#2D5016` / `#B6D481`
- `appAccent` → `#A3C46C` / `#5A8A3C` (camera-roll dot, map pin)
- `appTint` → `#E8F0D8` / `#283019` (badge backgrounds, tag chips)
- `deleteColor` = `#C84040`
- `rollDot` = `#A3C46C`

### Data Model (SQLite v1)

| Table | Key columns |
|---|---|
| `field_items` | `id`, `file_path` (nullable), `type` (0=photo/1=video/2=obs), `source` (0=app/1=roll), `captured_at`, `tags` (JSON `List<List<String>>`), `lat`, `lng`, `is_obs_only` |
| `sightings` | `id`, `item_id`, `observed_at`, `lat`, `lng` |
| `taxonomy_nodes` | `id`, `name`, `parent_id`, `sort_order` |
| `search_history` | `id`, `filter_labels` (JSON), `date_from`, `date_to`, `searched_at`, `result_count` |

`addItem()` in `ItemsNotifier` always auto-creates one initial sighting (capture date + GPS if available).

### Taxonomy Tree

`TaxonomyNotifier` in `taxonomy_provider.dart`:
- Seeded on first launch (empty table) from `_defaultTaxonomy()`: Animalia, Plantae, Incertae sedis with sub-taxa in Latin
- `addNode(name, parentId)` — adds child; `deleteNode(id)` — cascades to all descendants
- `flatList` — depth-first flat list; `pathForId(id)` — returns `["Animalia", "Insecta", "Coleoptera"]`

**Observation count badges** (in `taxonomy_screen.dart`): Use `ref.watch(sightingsProvider)` + `ref.watch(itemsProvider)` to compute total sightings across the node's entire subtree. Counts sightings, not items.

### Tags Format

`tags` is `List<List<String>>`. Each inner list is a full taxonomy path, e.g. `[["Animalia", "Insecta", "Coleoptera"], ["Plantae"]]`. `item.topLevelCategory` returns the first element of the first path. `item.lastTag` returns the last element of the first path (used as the tile label).

### Coordinate System

All item GPS is stored as WGS84 (`lat`/`lng`). Display format is controlled by `settings.coordSystem`:
- `CoordSystem.gps` → `formatGps()` → `"46.9521° N  7.4482° E"`
- `CoordSystem.lv95` → `wgsToLV95()` + `formatLV95()` → `"E 2'600'072  N 1'200'147"`

### Map Overlay

`MapOverlaySheet.show(context, lat, lng)` — bottom sheet widget in `shared/widgets/map_overlay.dart`. Renders 3×3 Swisstopo WMTS tiles at zoom 15 with a green crosshair, or a system maps placeholder. "Open in …" button uses `url_launcher`:
- Swisstopo web: `https://map.geo.admin.ch/?lang=en&E={lv95E}&N={lv95N}&zoom=10`
- Apple Maps (iOS): `maps.apple.com/?ll={lat},{lng}`
- Google Maps (Android): `geo:{lat},{lng}`

### Photo Viewer

`photo_viewer_screen.dart` contains three embedded classes:
- `_SightingSheet` — log additional sighting (date picker + GPS toggle)
- `_ReclassifySheet` — edit taxonomy tags (Browse tree or Find mode), saves via `itemsProvider.notifier.updateTags()`

Both open via `showModalBottomSheet`.

### Localisation

ARB files: `lib/l10n/app_en.arb` (default), `app_de.arb`, `app_it.arb`, `app_fr.arb`. Generated output in `lib/l10n/generated/`. Run `flutter gen-l10n` after any ARB edit. Access via `AppLocalizations.of(context)!`.

---

## iOS Signing

- **Bundle ID:** `com.mpeditech.fieldtaxa`
- **Apple Developer account:** `dev@mpeditech.ch`
- **Team ID:** `Q3N4UPBWMB`
- **Code sign style:** Automatic
- **Code sign identity:** `Apple Development`

---

## App Icon

Master SVG: `fieldtaxa/assets/icon_a3.svg`. All 15 iOS sizes pre-generated in `fieldtaxa/ios/Runner/Assets.xcassets/AppIcon.appiconset/` using Inkscape (`/opt/homebrew/bin/inkscape`). To regenerate:

```bash
inkscape assets/icon_a3.svg --export-type=png --export-filename=<out>.png --export-width=<px> --export-height=<px>
```

---

## Important Implementation Notes

### Non-obvious behaviours
- `_obsCount()` in taxonomy screen must watch **both** `itemsProvider` and `sightingsProvider` — counts sightings (not items), aggregated from the full subtree.
- `addItem()` auto-creates the first sighting; any subsequent sightings are added via `SightingsNotifier.addSighting()`.
- `PhotoTile` navigates to `/viewer/:itemId` on tap.
- The "See all →" row in `GalleryScreen` appears only when a category has more than 9 items (`_galleryCap = 9`).
- `_HistoryRow` in `search_screen.dart` is tappable — calls `_restoreFromHistory()` which looks up node IDs by label name and re-runs the search.
- `taxon_observations_screen.dart` imports `dart:io` for `File(item.filePath!)` in thumbnails.

### Git commit convention
Commits from the repo root `/Users/michelpedimina/Work/FieldTaxa/` staging files with full relative paths (e.g. `git add fieldtaxa/lib/...`).
