# FieldTaxa

**FieldTaxa** is a Flutter app for iOS and Android that lets field researchers capture, classify, and track observations of fauna, flora, and other taxa. Each photo or GPS observation is tagged with a hierarchical taxonomy tree, and every sighting can be logged with date and location independently of new photos.

Developed by [MPediTech](https://www.mpeditech.com) · dev@mpeditech.ch

---

## Features

- **Gallery** — items grouped by top-level taxonomy category, 9-item preview with "See all" drill-down
- **Taxonomy tree** — fully editable hierarchy; node badges show total sighting counts aggregated across all descendants
- **Taxon Observations** — per-node observation list with photo thumbnails, sighting sub-rows, GPS links, and first/last date stats
- **Multi-sighting logging** — log additional sightings (date + optional GPS) against any existing item without re-importing the photo
- **Capture & Classify** — take a photo or video, import from the camera roll, then assign one or more taxonomy paths via a Browse-tree or Find mode
- **Edit Classification** — reclassify any item at any time from the Photo Viewer
- **Search** — filter by category (checkbox tree) and/or date range with collapsible date picker; recent searches saved and tappable to restore
- **Map Overlay** — Swisstopo WMTS tile view or System Maps, tappable from any coordinate display
- **Swiss LV95 / GPS coordinate toggle** — coordinates formatted in decimal degrees or Swiss LV95 throughout
- **Localisation** — English, Deutsch, Italiano, Français
- **Light / Dark / System theme**
- **Storage mode** — app-only, camera roll, or both in parallel

---

## Tech Stack

| Concern | Package |
|---|---|
| State management | `flutter_riverpod` ^2.6.1 |
| Navigation | `go_router` ^15.1.2 |
| Local database | `sqflite` ^2.4.1 |
| Settings persistence | `shared_preferences` ^2.3.4 |
| Typography | `google_fonts` ^6.2.1 (Plus Jakarta Sans + Newsreader) |
| Camera / media | `image_picker` ^1.1.2 |
| Location | `geolocator` ^13.0.4 |
| Maps | `cached_network_image` ^3.4.1 + Swisstopo WMTS |
| SVG | `flutter_svg` ^2.0.17 |
| URLs | `url_launcher` ^6.3.1 |
| Localisation | Flutter ARB + `flutter_localizations` |

---

## Project Commands

All commands run from inside `./fieldtaxa/`:

```bash
cd fieldtaxa

# Install dependencies
flutter pub get

# Generate localisation files (run after editing any .arb file)
flutter gen-l10n

# Run on simulator / device
flutter run

# Lint
flutter analyze --no-pub

# Format
dart format .

# Run tests
flutter test

# Build iOS release
flutter build ios --release

# Build Android APK
flutter build apk --release
```

---

## Project Structure

```
fieldtaxa/lib/
  core/
    db/           database_helper.dart     — SQLite singleton, schema v1
    models/       models.dart              — FieldItem, Sighting, TaxonomyNode, …
    providers/    items_provider.dart      — ItemsNotifier, SightingsNotifier, SearchHistoryNotifier
                  taxonomy_provider.dart   — TaxonomyNotifier (tree + seed)
                  settings_provider.dart   — SettingsNotifier
    router/       router.dart              — GoRouter with ShellRoute
    theme/        app_theme.dart           — All design tokens + theme builders
    utils/        coords.dart              — WGS84 ↔ LV95 conversion helpers
  features/
    capture/      capture_screen.dart
    classify/     classify_screen.dart
    gallery/      gallery_screen.dart · category_screen.dart
    search/       search_screen.dart
    settings/     settings_screen.dart · about_screen.dart
    taxonomy/     taxonomy_screen.dart · taxon_observations_screen.dart
    viewer/       photo_viewer_screen.dart (includes SightingSheet + ReclassifySheet)
  shared/widgets/
    map_overlay.dart
    photo_tile.dart
    shell_scaffold.dart
  l10n/           app_en.arb · app_de.arb · app_it.arb · app_fr.arb
```

---

## Data Model (SQLite v1)

| Table | Purpose |
|---|---|
| `field_items` | Photos, videos, and obs-only items with taxonomy tags (JSON) and GPS |
| `sightings` | One or more timestamped + optional GPS records per item |
| `taxonomy_nodes` | Hierarchical taxonomy (id, name, parent_id, sort_order) |
| `search_history` | Last 20 searches (filter labels, date range, result count) |

---

## Navigation

```
/ (Gallery)            ← ShellRoute with bottom nav
/category/:name        ← Category drill-down (Gallery tab active)
/search                ← Search screen
/taxonomy              ← Taxonomy tree
/taxonomy/observations/:nodeId   ← Taxon observations
/settings              ← Settings
/settings/about        ← About screen
/capture               ← Camera (no bottom nav)
/classify/:draftId     ← Classify screen (no bottom nav)
/viewer/:itemId        ← Photo viewer (pushed as overlay)
```

---

## iOS Distribution

- **Bundle ID:** `com.mpeditech.fieldtaxa`
- **Apple Developer account:** `dev@mpeditech.ch`
- **Team ID:** `Q3N4UPBWMB`
- **Code signing:** Automatic (`CODE_SIGN_STYLE = Automatic`)
- **Minimum iOS:** 13.0

---

## Localisation

Edit `.arb` files in `lib/l10n/`, then regenerate:

```bash
flutter gen-l10n
```

Never edit the generated files in `lib/l10n/generated/` directly.

---

## Version History

| Version | Build | Notes |
|---|---|---|
| 1.0.0 | 1 | Initial release — gallery, taxonomy, capture, classify, search, sighting logging, map overlay |
