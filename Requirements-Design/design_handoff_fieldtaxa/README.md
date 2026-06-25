# FieldTaxa — Flutter App Design Handoff

**Developer:** MPediTech · www.mpeditech.com  
**Technology:** Flutter (iOS + Android)  
**Design fidelity:** High-fidelity — pixel-accurate prototype with final colors, typography, spacing, icons, and interactions.

---

## About the Design Files

The files in this bundle are **high-fidelity interactive prototypes built in HTML**. They are design references showing the intended look, behaviour, and interactions — not production code to copy.

Your task is to **recreate these designs in Flutter** using Flutter's widget system, navigation, and community packages. Open `FieldTaxa Reference.html` in any browser to interact with the full prototype alongside this document.

---

## App Identity

| | |
|---|---|
| **Name** | FieldTaxa |
| **Developer** | MPediTech |
| **Website** | www.mpeditech.com |
| **Version** | 1.0.0 (beta) |
| **Platforms** | iOS + Android |
| **Languages** | English (default), Deutsch, Italiano, Français |

---

## App Icon

File: `assets/icon_a3.svg`

The master icon SVG is at `assets/icon_a3.svg` — a vector file that scales to any resolution. Export it at the following sizes for each platform:

### iOS (required sizes)
| Usage | Size |
|---|---|
| App Store | 1024×1024 |
| Home screen @3x | 180×180 |
| Home screen @2x | 120×120 |
| Spotlight @3x | 87×87 |
| Notification @3x | 60×60 |

### Android (required sizes)
| Usage | Size |
|---|---|
| Play Store | 512×512 |
| XXXHDPI | 192×192 |
| XXHDPI | 144×144 |
| XHDPI | 96×96 |
| HDPI | 72×72 |

### Icon design details
- **Background:** linear gradient `#1E3A2E` → `#142818` (top to bottom)
- **Corner radius:** applied by the platform (iOS uses continuous squircle mask; Android uses adaptive icon)
- **Coordinate grid:** white lines at 22% opacity (horizontal: y=20, y=40 / vertical: x=20, x=40)
- **Terrain fill:** undulating path at base (7% white)
- **Field route:** winding path (15% white, 1.5px stroke, round caps)
- **Map pin:** solid `#A3C46C` teardrop shape with white inner circle (opacity 90%)
- **Cladogram trunk + branches:** white, 2.4px round stroke
- **Leaf nodes — Fauna (left):** `#7EBBF0` (sky blue), radius 3
- **Leaf nodes — Flora (right):** `#F0C84A` (amber), radius 3
- **Internal nodes:** white 40% opacity, radius 2

---

## Design Tokens

### Colors — Light Mode
| Token | Hex | Usage |
|---|---|---|
| `--bg` | `#EEEEE5` | App background |
| `--surface` | `#FFFFFF` | Cards, sheets, nav bar |
| `--surface2` | `#F5F6EF` | Input backgrounds, segmented controls |
| `--line` | `#E3E4D9` | Dividers, borders |
| `--primary` | `#2D5016` | Primary action, active nav, buttons |
| `--primary2` | `#5A8A3C` | Secondary green, observation count badges |
| `--accent` | `#A3C46C` | Camera-roll indicator, map pin |
| `--tint` | `#E8F0D8` | Light green tint, tag chip backgrounds |
| `--fg` | `#1B2410` | Primary text |
| `--muted` | `#74795F` | Secondary text, placeholders, icons |
| `--chrome` | `#FFFFFF` | Top/bottom nav bar background |
| `--delete` | `#C84040` | Delete/trash actions |

### Colors — Dark Mode
| Token | Hex | Usage |
|---|---|---|
| `--bg` | `#12140D` | App background |
| `--surface` | `#1E221A` | Cards, sheets |
| `--surface2` | `#262B1E` | Input backgrounds |
| `--line` | `#313625` | Dividers, borders |
| `--primary` | `#B6D481` | Primary action (inverted) |
| `--primary2` | `#90BC5C` | Secondary green |
| `--accent` | `#5A8A3C` | Accent |
| `--tint` | `#283019` | Tint backgrounds |
| `--fg` | `#EAEFDC` | Primary text |
| `--muted` | `#9AA384` | Secondary text |
| `--chrome` | `#171A12` | Nav bar background |

**Theme modes:** Light / Dark / System (auto). User-selectable in Settings.

### Typography
| Role | Font | Size | Weight |
|---|---|---|---|
| App title / screen headers | Newsreader (serif) | 24–30sp | SemiBold 600 |
| Section titles | Newsreader | 19–22sp | SemiBold 600 |
| Body / labels | Plus Jakarta Sans | 13–14.5sp | Medium 500 / SemiBold 600 |
| Monospace (coordinates) | System monospace | 11–14sp | SemiBold 600 |
| Captions / meta | Plus Jakarta Sans | 10.5–12sp | SemiBold 600 |
| Buttons | Plus Jakarta Sans | 12–14sp | Bold 700 |

Add `plus_jakarta_sans` and `newsreader` via `google_fonts` package.

### Spacing & Radius
| Value | Usage |
|---|---|
| 3px | Photo tile grid gap |
| 9px | Small button radius |
| 12–13px | Cards, input fields radius |
| 14px | Photo tile radius (viewer) |
| 18–22px | Screen horizontal padding |
| 20px | Pills, tag chips radius |

---

## Navigation Architecture

Use **GoRouter**. Bottom navigation bar with 5 items persists on all screens except Capture and Classify.

| Route | Screen |
|---|---|
| `/` | Gallery |
| `/category/:name` | Category drill-down |
| `/search` | Search |
| `/taxonomy` | Taxonomy tree |
| `/taxonomy/observations/:nodeId` | Taxon Observations |
| `/settings` | Settings |
| `/settings/about` | About |
| `/capture` | Camera / Capture |
| `/classify/:draftId` | Classify photo |

### Bottom Navigation Bar
| Pos | Icon | Label | Route | Notes |
|---|---|---|---|---|
| 1 | 2×2 grid squares | Gallery | `/` | Active on category screen too |
| 2 | Search circle | Search | `/search` | |
| 3 | Camera FAB | — | `/capture` | 54×54px circle, `--primary` bg, raised 12px |
| 4 | Node graph | Taxonomy | `/taxonomy` | Active on taxon obs screen too |
| 5 | Gear cog | Settings | `/settings` | Active on About too |

---

## Data Model

```dart
enum ItemType { photo, video, obs }   // obs = standalone observation (no photo)
enum StorageSource { app, roll }
enum StorageMode { appOnly, rollOnly, both }
enum ThemePreference { light, dark, system }
enum CoordSystem { gps, lv95 }
enum MapProvider { systemMaps, swisstopo }

class FieldItem {
  final String id;
  final String? filePath;        // null for obs-only items
  final ItemType type;
  final StorageSource source;
  final DateTime capturedAt;
  final List<List<String>> tags; // e.g. [["Animals","Birds","Raptors"]]
  final double? lat;
  final double? lng;
  final bool isObsOnly;          // true = no photo, GPS observation only
}

class Sighting {
  final String id;
  final DateTime observedAt;
  final double? lat;
  final double? lng;
}

class TaxonomyNode {
  final String id;
  String name;
  List<TaxonomyNode> children;
}

class SearchHistoryEntry {
  final String id;
  final List<String> filterLabels;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final DateTime searchedAt;
  final int resultCount;
}

class AppSettings {
  ThemePreference themeMode;
  String language;               // "en" | "de" | "it" | "fr"
  StorageMode storageMode;
  CoordSystem coordSystem;       // GPS or Swiss LV95
  MapProvider mapProvider;       // systemMaps or swisstopo
}
```

### Sightings (per FieldItem)
Each `FieldItem` has an associated list of `Sighting` records. The first sighting is automatically created when the item is classified (using the capture date and GPS if recorded). Additional sightings are logged by the user without taking a new photo.

---

## Coordinate Systems

Two modes selectable in Settings:

### GPS (decimal degrees)
Format: `46.9521° N  7.4482° E`

### Swiss LV95 (metric)
Format: `E 2'600'072  N 1'200'147`

Use the Swisstopo approximation formulas to convert WGS84 → LV95:

```dart
Map<String, int> wgsToLV95(double lat, double lng) {
  final phi = (lat * 3600 - 169028.66) / 10000;
  final lam = (lng * 3600 - 26782.5) / 10000;
  final E = 2600072.37 + 211455.93*lam - 10938.51*lam*phi
            - 0.36*lam*phi*phi - 44.54*lam*lam*lam;
  final N = 1200147.07 + 308807.95*phi + 3745.25*lam*lam
            + 76.63*phi*phi - 194.56*lam*lam*phi + 119.79*phi*phi*phi;
  return { 'E': E.round(), 'N': N.round() };
}
```

Note: LV95 is only accurate within Swiss territory. Display a warning note in Settings.

---

## Map Integration

Two modes selectable in Settings:

### System maps
- iOS: open `maps.apple.com/?ll={lat},{lng}`
- Android: open `geo:{lat},{lng}?q={lat},{lng}`

### Swisstopo
- Map tiles (WMTS): `https://wmts.geo.admin.ch/1.0.0/ch.swisstopo.pixelkarte-farbe/default/current/3857/{z}/{x}/{y}.jpeg`
- Deep link: `https://map.geo.admin.ch/?lang={locale}&E={lv95E}&N={lv95N}&zoom=10`
- Show a 3×3 grid of tiles at zoom level 15, centered on the observation point
- Tile coordinates: standard WebMercator XYZ

```dart
({int x, int y}) latLngToTile(double lat, double lng, int zoom) {
  final n = math.pow(2, zoom);
  final x = ((lng + 180) / 360 * n).floor();
  final latRad = lat * math.pi / 180;
  final y = ((1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) / 2 * n).floor();
  return (x: x, y: y);
}
```

---

## Screens

---

### 1. Gallery

**Purpose:** Browse all photos/videos grouped by top-level taxonomy category.

**Header (sticky):** MPediTech logo (44dp height) + "FieldTaxa" in Newsreader 22sp below it, left-aligned. Count pill right (`--surface2` bg, `--muted` text, 20dp radius).

**Gallery cap:** Max **9 photos** per category in the main view. If more exist, show a "See all N →" row at the bottom of the group (`--tint` bg, `--primary` text 13sp Bold, right chevron, full-width tap).

**Photo tile:**
- `aspect-ratio: 1:1`, `overflow: hidden`
- Background image fills tile (object-fit: cover)
- Dark gradient overlay on bottom third
- Last taxonomy tag, bottom-left, 10.5sp white bold, text shadow
- Video badge: semi-dark rounded rect top-right with play icon — if `type == video`
- Camera-roll dot: `#A3C46C` 7dp circle top-left — if `source == roll`

---

### 2. Category Drill-Down

**Purpose:** All photos for one taxonomy category.

**Header:** ← Gallery (primary, 14sp bold) | category name (Newsreader 17sp) centered | count pill right.
**Grid:** 3-column, 3dp gap, 3dp padding. Same tiles as Gallery.
**Gallery tab active.** Uses `GridView.builder` for lazy rendering.

---

### 3. Search

**Purpose:** Filter by taxonomy categories + date range.

**Search field:** `--surface2` bg, 13dp radius, search icon.

**Active filters:** Tag chips (primary bg, white text) + "Clear" link + full-width "Search" button.

**Date range (collapsible):** Calendar icon + "Date range" label + "Active" badge + chevron (rotates on expand). Expanded: From/To `DatePicker` in 2-column grid.

**Category list:** All taxonomy nodes indented by `depth × 14dp`. Checkbox (primary fill when selected) + label.

**Search logic:** Categories AND date range combined. `capturedAt >= from AND capturedAt <= to`.

**Search history:** Clock icon + label + date + result count badge (`--tint` bg, `--primary2` text).

---

### 4. Taxonomy Tree

**Purpose:** Browse and configure the category tree.

**Each row (indented by `depth × 18dp`):**
- **Chevron button** (30×44dp): rotates 90° when expanded (150ms)
- **Name button** (flex-1): tap → Taxon Observations screen. Shows observation count badge (`--tint` bg, `--primary2` text, 9dp radius)
- **+ button** (32×34dp, `--surface2` bg): adds child node
- **Trash button** (32×34dp, `rgba(200,40,40,.07)` bg, `#C84040` icon): deletes node + all children

**"Add category"** dashed-border full-width button at bottom.

**Observation count** per node = total sightings across all photos tagged to that node OR any descendant.

---

### 5. Taxon Observations

**Purpose:** All observations for a selected taxon node, with individual sighting records.

**Header:** ← Taxonomy | node name (Newsreader 16sp) | total sightings count badge.

**Stats bar (3 columns):** First obs date | Last obs date | GPS sightings count.

**"Add observation (no photo)"** button at top of list — creates a `FieldItem` with `isObsOnly: true`, current timestamp, GPS position. Shown with a pin icon placeholder instead of a photo.

**Observation rows (per FieldItem):**
- Top row (tappable → viewer): 58×58dp thumbnail (or pin icon for obs-only) | taxa label | sighting count badge `N×` | date | → chevron
- Sighting sub-rows (always visible, indented 89dp): pin icon | date/time | GPS coordinate (formatted per coordSystem setting, monospace, tappable → map overlay)

---

### 6. Capture

**Purpose:** Camera viewfinder, photo/video capture, camera roll import.

**Full-screen dark.** No bottom nav.

- Viewfinder fills ~70% height
- Focus reticle: 88dp white-border rounded square, centered
- Top hint pill: "Tap to capture" frosted
- Photo/Video toggle
- Roll thumbnail (50×50dp, last roll image)
- Shutter button (72dp circle, white border, inner ring)
- Close X → Gallery
- "Import from camera roll" pill button

---

### 7. Import Sheet (bottom sheet)

Roll thumbnails in 3-column grid. Max 340dp height. Tap → Classify screen.

---

### 8. Classify

**Purpose:** Tag a captured or imported item. Full-screen, no bottom nav.

**Header:** Cancel | "Classify" | Save pill.

**Preview + tags:** 84×84dp thumbnail left; tag chips (`--tint` bg, `--primary` text, × remove button) right.

**Mode toggle:** "Browse tree" | "Find" (segmented control).

**GPS toggle:** Pin icon + label + toggle switch. When ON: simulates/records GPS position, shows formatted coordinates.

**Browse tree mode:** Breadcrumb path + node list. Each node: + button (adds full path as tag) + drill button (chevron if has children).

**Find mode:** Search field + flat node list with + button per row.

---

### 9. Photo Viewer

**Purpose:** Full-screen view of a single photo/video.

**Dark overlay** (`rgba(8,11,4,.92)`), full-screen.

**Bottom area:**
- Tag chips (frosted dark bg, white text)
- **Coordinate row (tappable → Map Overlay):** pin icon (`#A8D87A`) + coordinate string (monospace, white 90%) + external link icon. Formatted per coordSystem setting.
- Camera-roll banner (if applicable): `rgba(163,196,108,.16)` bg
- **"Log sighting" button:** `rgba(255,255,255,.1)` bg, pin icon, label, sighting count badge

---

### 10. Sighting Sheet (bottom sheet)

**Purpose:** Log a new sighting without a new photo.

- Date/time picker (pre-filled: now), `datetime-local`
- GPS toggle (same style as Classify)
- Save button (primary bg, full-width)

---

### 11. Map Overlay

**Purpose:** Show observation location on a map.

**Triggered by:** tapping a coordinate anywhere in the app.

**Bottom sheet over dark backdrop:**
- Header: coordinate label (monospace) + close X button
- **Map area (240dp height):**
  - Swisstopo: 3×3 grid of WMTS tiles at zoom 15, 3dp gap, green crosshair marker centered
  - System maps: styled placeholder with pin icon + note
- **"Open in …" button:** routes to Apple Maps / Google Maps / map.geo.admin.ch per settings

---

### 12. Settings

**Sections:**
1. **LANGUAGE** — 2×2 grid: English / Deutsch / Italiano / Français. Active = `--primary` bg + white text.
2. **APPEARANCE** — 3-segment: Light / Dark / System.
3. **STORAGE LIBRARY** — 3 stacked rows: In-app only / Camera roll / Both. Active = 2px `--primary` border + dot indicator.
4. **COORDINATES** — 2-segment: GPS / Swiss LV95. Note: "Swiss territory only — LV95 outside Switzerland may be inaccurate."
5. **MAPS** — 2-segment: System maps / Swisstopo.
6. **PREVIEW DEVICE** — Remove from production app (prototype-only).
7. **About** row → About screen.

---

### 13. About

**Centered section:** MPediTech logo (52dp) + "FieldTaxa" (Newsreader 30sp) + description.

**Info card (bordered, dividers):** Version · Build · Release date · Developer · Website.

**Footer:** leaf icon + "FieldTaxa · © 2026 MPediTech".

---

## Animations & Transitions

| Interaction | Flutter implementation |
|---|---|
| Screen fade in (300ms) | `FadeTransition` in GoRouter route builder |
| Modal bottom sheet slide up | `showModalBottomSheet` with animation |
| Classify slide up (18dp + fade) | Custom `SlideTransition` |
| Taxonomy chevron rotate | `AnimatedRotation` 0→90°, 150ms |
| GPS toggle | `AnimatedContainer` bg color, 200ms |
| Map overlay | `showModalBottomSheet` with dark scrim |

---

## Initial Taxonomy Seed Data

```
Animals
  Insects
    Terrestrial
    Aquatic > Insecta > Ephemeroptera > Baetidae > Baetis
  Birds
    Seed-feeding
    Raptors
Plants
  Trees
  Mountain flowers
Springs
  Holocrene
  Rheocrene
  Limnocrene
```

Persist tree to Hive or SQLite. Changes apply immediately — no Save step.

---

## Recommended Flutter Packages

| Package | Purpose |
|---|---|
| `go_router` | Declarative routing / deep links |
| `riverpod` or `flutter_bloc` | State management |
| `camera` | Live camera capture |
| `image_picker` | Camera roll import |
| `photo_manager` | Roll browsing + deletion monitoring |
| `cached_network_image` | Image caching |
| `hive` or `sqflite` | Local persistence |
| `flutter_localizations` + `intl` | EN/DE/IT/FR localisation |
| `google_fonts` | Plus Jakarta Sans + Newsreader |
| `path_provider` | App document directory |
| `video_player` | In-app video playback |
| `geolocator` | GPS position recording |
| `url_launcher` | Open external maps |
| `cached_network_image` | Swisstopo tile caching |

---

## Localisation Keys

All string keys (with EN values) — replicate for DE, IT, FR:

```
gallery, search, capture, taxonomy, settings, classify, save, cancel,
addTag, importRoll, photo, video, shutter, language, appearance, storage,
light, dark, auto, appOnly, rollOnly, both, platform, results, recent,
selectCats, runSearch, clear, addCategory, drillMode, searchMode, back,
tagsOn, noTags, linked, linkedNote, items, newCat, editTree, unclassified,
chooseFromRoll, platformNote, dateRange, from, to, active, about, version,
developer, website, releaseDate, appDesc, seeAll, gpsLocation, obs,
firstObs, lastObs, locations, logSighting, obsDateTime, addObs,
coordLabel, mapLabel, defaultMaps, openIn, openMapsNote, lv95Note,
coordinates
```

See the prototype's JS `T` object for all 4 language translations.

---

## Storage Behaviour

| Mode | Behaviour |
|---|---|
| **In-app only** | Files in app document directory. Can import from camera roll (copies). |
| **Camera roll** | Metadata + tags only; files stay on roll. Monitor deletions via `photo_manager` change API — auto-remove orphaned entries. |
| **Both** | Files saved to both. Roll items shown with `#A3C46C` green dot indicator. |

---

## Assets

| File | Usage |
|---|---|
| `assets/icon_a3.svg` | Master app icon (vector, scales to any size) |
| `assets/MPeditechLogo.png` | Gallery header (44dp height), About screen (52dp height) |

The prototype uses remote placeholder photos (picsum.photos). In production, replace with `Image.file` / `CachedNetworkImage` from local storage.

---

## Files in This Bundle

| File | Description |
|---|---|
| `README.md` | This document — complete Flutter implementation spec |
| `FieldTaxa Reference.html` | Fully interactive prototype — open in any browser |
| `assets/icon_a3.svg` | App icon master SVG (A3 design: cladogram + map grid) |
| `assets/MPeditechLogo.png` | MPediTech brand logo (transparent PNG) |

---

## Notes for Claude Code

1. **Do not copy HTML/JS prototype code** — recreate each screen as native Flutter widgets
2. The prototype's `T` object in JS contains all 4-language translations → use as basis for `.arb` files
3. The `renderVals()` function shows the full state/derived data logic → reference for state management
4. `GALLERY_CAP = 9` — photos shown per category in main gallery view
5. Remove the "Preview device" toggle from Settings — prototype-only
6. Search + observation count runs client-side — no network calls
7. Taxonomy changes persist immediately — no Save step
8. LV95 conversion is an approximation — accurate to ~1m within Switzerland
9. The Swisstopo WMTS is publicly accessible (no API key needed for raster tiles)
10. Each `FieldItem` can have multiple `Sighting` records (date + GPS) without requiring a new photo

---

*Design by MPediTech using Claude · June 2026*
