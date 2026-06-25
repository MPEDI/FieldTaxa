# Handoff: FieldTaxa — Flutter App Design Specification

## Overview
FieldTaxa is a field-observation media manager for professional biologists, ecologists, and citizen scientists. Users capture or import photos and videos, classify them against a configurable scientific taxonomy tree, and search/filter their collection by category, date range, and source.

**Developer / Publisher:** MPediTech · www.mpeditech.com

---

## About the Design Files
The files in this bundle are **high-fidelity interactive prototypes created in HTML** — they show the intended look, behaviour, and interactions of the app, but are NOT production code to copy directly.

Your task is to **recreate these designs in Flutter**, using Flutter's widget system, navigation patterns, and community packages. Open `FieldTaxa Reference.html` in any browser to interact with the full prototype.

**Target platform:** iOS and Android (Flutter cross-platform)

---

## Fidelity
**High-fidelity.** The prototype is pixel-accurate with final colors, typography, spacing, icons, and interactions. Recreate the UI to match as closely as Flutter's rendering allows.

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
| `--primary2` | `#5A8A3C` | Secondary green, accents |
| `--accent` | `#A3C46C` | Camera-roll dot indicator |
| `--tint` | `#E8F0D8` | Light green tint backgrounds |
| `--fg` | `#1B2410` | Primary text |
| `--muted` | `#74795F` | Secondary text, placeholders |
| `--chrome` | `#FFFFFF` | Top/bottom nav bar background |

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

**Theme mode:** Light / Dark / System (auto) — user-selectable in Settings.

### Typography
| Role | Font | Size | Weight |
|---|---|---|---|
| App title / screen headers | Newsreader (serif) | 24–30px | SemiBold 600 |
| Section titles | Newsreader | 19–22px | SemiBold 600 |
| Body / labels | Plus Jakarta Sans | 13–14.5px | Medium 500 / SemiBold 600 |
| Captions / meta | Plus Jakarta Sans | 10.5–12px | SemiBold 600 |
| Buttons | Plus Jakarta Sans | 12–14px | Bold 700 |

Add `plus_jakarta_sans` and `newsreader` via the `google_fonts` package, or bundle TTF files directly.

### Spacing & Border Radius
| Value | Usage |
|---|---|
| 3px | Photo tile grid gap |
| 9px | Small button radius |
| 12–13px | Cards, input fields radius |
| 14px | Photo tile radius in viewer |
| 18–22px | Screen horizontal padding |
| 20px | Pills, tag chips radius |
| 110px | Bottom scroll padding (for nav bar) |

---

## App Architecture

### Navigation (GoRouter recommended)
| Route | Screen |
|---|---|
| `/` | Gallery |
| `/category/:name` | Category drill-down |
| `/search` | Search |
| `/taxonomy` | Taxonomy tree |
| `/settings` | Settings |
| `/settings/about` | About |
| `/capture` | Camera / Capture |
| `/classify/:draftId` | Classify photo |

Bottom navigation bar with 5 items persists on ALL screens except `/capture` and `/classify`.

### State Management (Riverpod or Bloc)
| State | Description |
|---|---|
| `PhotosState` | All photos/videos; add/delete operations |
| `TaxonomyState` | Category tree (nested nodes); add/delete |
| `SearchState` | Active filters, date range, results, history |
| `DraftState` | Photo being classified (tags, source, type) |
| `AppSettingsState` | Language, theme mode, storage mode |

### Localisation
Use `flutter_localizations` + `intl`. Locales: **en, de, it, fr**. Default: device locale, fallback to en.
All string keys are in the prototype's `T.en / T.de / T.it / T.fr` objects (see HTML source).

---

## Screens

---

### 1. Gallery Screen

**Purpose:** Browse all photos/videos grouped by top-level taxonomy category.

**Layout:**
- Sticky header: MPediTech logo (44px height) with "FieldTaxa" in Newsreader 22px below it, left-aligned. Count pill (`#F5F6EF` bg, `#74795F` text, 20px radius) right-aligned
- Background: `#EEEEE5`
- Per-category group: section header row (Newsreader 19px category name + horizontal rule + count) + 3-column photo grid
- **Gallery cap: show max 9 photos per category**
- "See all N →" row below the 9-tile grid if there are more photos. Full-width tap target, 11px top border (`--line`), label in `--primary` 13px Bold, right chevron in `--primary`

**Photo tile:**
- `aspect-ratio: 1/1`, `overflow: hidden`
- Background image fills tile (cover)
- Dark gradient overlay on bottom third
- Label (last taxonomy tag) bottom-left, 10.5px white bold
- Video badge: dark rounded rect top-right with play icon — shown if `type == video`
- Camera-roll dot: `#A3C46C` 7px circle top-left — shown if `source == roll`

**Flutter:** `CustomScrollView` with `SliverList` of groups; each group contains a `SliverGrid` (crossAxisCount: 3, mainAxisSpacing: 3, crossAxisSpacing: 3). Use `CachedNetworkImage` or `Image.file`.

---

### 2. Category Drill-Down Screen

**Purpose:** Show ALL photos in one taxonomy category.

**Layout:**
- Header: back chevron + "Gallery" label (primary color, 14px bold) left; category name (Newsreader 17px bold) centered; count pill right
- 3-column photo grid, 3px gap, 3px padding all sides
- Tiles identical to Gallery tiles
- Bottom nav visible; Gallery tab highlighted

**Flutter:** `GridView.builder` — lazy, handles thousands of items efficiently.

---

### 3. Search Screen

**Purpose:** Filter photos by taxonomy categories and/or date range; view search history.

**Layout:**
- Sticky header: "Search" (Newsreader 26px), search text field below (`#F5F6EF` bg, 13px radius, search icon)
- Active filter chips row + "Clear" link + full-width "Search" button (primary bg) — visible when filters or date range are set
- **Date range section** (collapsible): calendar icon + "Date range" label + "Active" badge when set + chevron. Expanded: From / To date pickers in 2-column grid
- Category checklist: "SELECT CATEGORIES" label (12px uppercase muted), flat list of taxonomy nodes indented by depth×14px. Each: 18px checkbox (primary fill when selected) + label
- Search results grid (3-col tiles) shown above filters when results exist
- Search history: "RECENT SEARCHES" header, cards with clock icon + label + date + result count badge (`#E8F0D8` bg, `--primary2` text)

**Search logic:** Category filters + date range combine with AND. Date range filters `capturedAt >= from AND capturedAt <= to`. Tapping a history item restores its filters and re-runs.

---

### 4. Taxonomy Screen

**Purpose:** Browse and configure the category tree.

**Layout:**
- Header: "Taxonomy" (Newsreader 26px) + hint text
- Flat list of visible nodes, indented by `depth × 18px`
- Each row: expand chevron (rotates 90° when expanded, 12px) + node name (14.5px bold) + child count | **+** button (32×34px, `--surface2` bg, 9px radius, primary icon) | **trash** button (32×34px, `rgba(200,40,40,.07)` bg, 9px radius, `#C84040` icon)
- "Add category" dashed-border button at bottom (full-width, 12px dashed `--line`, primary text + icon, 13.5px bold)

**Interactions:**
- Tap row → toggle expand/collapse with 150ms rotation animation
- Tap **+** → append new child node named with locale's "New category" string
- Tap **trash** → remove node and all children

---

### 5. Settings Screen

**Purpose:** Configure language, appearance, storage mode. Access About.

**Sections (22px horizontal padding, 18px top padding):**

1. **LANGUAGE** (12px uppercase label, 9px bottom margin) — 2×2 button grid (7px gap):
   - Each button: 13px radius, 13px; active = `--primary` bg + white text; inactive = `--surface` + `--line` border 1.5px
   - Options: English / Deutsch / Italiano / Français

2. **APPEARANCE** (same label style) — 3-segment control (`--surface2` bg, 4px padding, 13px radius):
   - Segments: Light / Dark / System; active = `--surface` bg + `--primary` text + shadow

3. **STORAGE LIBRARY** — 3 stacked option rows (7px gap):
   - Each: `--surface` bg card, 12px radius; leading 18px icon (primary stroke); label 13.5px bold; active dot 8px circle (primary) right
   - Active row: 2px `--primary` inset shadow border
   - Options: In-app only / Camera roll / Both in parallel

4. **PREVIEW DEVICE** — 2-segment (iOS / Android). **This section exists only in the prototype** to toggle the mock device chrome. Remove it from the production Flutter app.

5. **About row** (26px top, 22px top border `--line`): card row with info icon (tint bg, 10px radius), "About" label 14px bold, chevron right

---

### 6. About Screen

**Purpose:** App info and developer credits.

**Layout:**
- Back header: "← Settings" (primary color, 14px bold)
- Centered section (36px top padding, 28px bottom, border-bottom): MPediTech logo (50px height) + "FieldTaxa" (Newsreader 30px bold) + description (13px muted, 260px max-width)
- Info card (bordered 14px radius, 1px `--line` dividers): Version · Build · Release date · Developer · Website
- Footer row: small leaf icon (primary bg, 7px radius) + "FieldTaxa · © 2026 MPediTech" (12–12.5px)

**Values:** Version 1.0.0 (beta) · Build 2026.06 · June 2026 · MPediTech · www.mpeditech.com

---

### 7. Capture Screen

**Purpose:** Camera viewfinder for photo/video capture or camera-roll import.

**Layout:** Full-screen dark (`#0a0c07`), NO bottom nav.
- Viewfinder fills ~70% height with live camera feed
- Focus reticle: 88px white-border rounded square (1.5px, 8px radius), centered
- Top pill: locale's "Tap to capture" string in frosted pill (`rgba(0,0,0,.4)`, 11px bold white)
- Bottom strip (18px top padding, 30px bottom):
  - Photo/Video toggle: `rgba(255,255,255,.5)` inactive → white active, 12px bold uppercase, 20px radius pills
  - Roll thumbnail: 50×50px, 11px radius (last camera roll image or placeholder)
  - **Shutter**: 72×72px circle, white border 4px, inner circle with `#0a0c07` inset ring 2px
  - Close X: 50×50px, transparent, white SVG X icon
- "Import from camera roll" pill button: `rgba(255,255,255,.12)` bg, white text, 24px radius

**Flutter packages:** `camera` (viewfinder), `image_picker` (import), `photo_manager` (roll picker sheet).

---

### 8. Import Sheet

**Purpose:** Pick from camera roll (modal bottom sheet).

**Layout:** 24px top radius, drag handle (38×5px, 3px radius, `--line` color). Title "Choose from camera roll" 15px bold. 3-column grid of roll thumbnails (8px radius, square), max 340px height scrollable.

---

### 9. Classify Screen

**Purpose:** Tag a newly captured or imported item with taxonomy categories.

**Layout:** Full-screen, NO bottom nav.
- Header bar: "Cancel" (muted, 14px bold) | "Classify" (15px bold) | "Save" (primary bg, white, 13px bold, 20px radius pill)
- Item preview row (16px top padding): 84×84px tile (14px radius, overflow hidden) left + tags panel right
  - Tags panel: "Categories on this item" label (13px bold), then tag chips (`--tint` bg, `--primary` text, 11px, × remove button)
  - When empty: muted "No categories yet" placeholder
- **Mode toggle**: "Browse tree" | "Find" (segmented control, `--surface2` bg, 4px padding, 12px radius)

**Browse tree mode (14px top padding):**
- Breadcrumb row: "← Back" button (primary, `--surface2` bg, 8px radius) + path crumbs (`--muted`, 12px bold each)
- Node list: each row has a **+** button left (36×44px, `--surface` bg, 11px radius, primary icon) and a drill button right (flex-1, `--surface` bg, 11px radius, label + chevron if has children)
- "Add this category" button below (full-width, `--tint` bg, `--primary` text, 13.5px bold) — visible when depth > 0

**Find mode (14px top padding):**
- Search field (`--surface2` bg, 12px radius)
- Flat list of all taxonomy nodes, indented depth×14px. Each: full-width row with path label left + **+** icon right

---

## Interactions & Animations

| Interaction | Flutter equivalent |
|---|---|
| Screen fade in (300ms) | `FadeTransition` in route builder |
| Modal sheet slide up | `showModalBottomSheet` with `AnimationController` |
| Classify screen slide up | Custom `SlideTransition` (18px vertical + fade) |
| Taxonomy chevron | `AnimatedRotation` 0→90°, 150ms |
| Theme switch | `AnimatedTheme` or `ThemeMode` update |

---

## Bottom Navigation Bar

5 items; center item is a raised FAB:

| Pos | Icon | Label | Route | Notes |
|---|---|---|---|---|
| 1 | 2×2 grid squares | Gallery | `/` | Also active on category screen |
| 2 | Search circle | Search | `/search` | |
| 3 | Camera FAB | — | `/capture` | 54×54px circle, `--primary` bg, 6px shadow, raised 12px above bar |
| 4 | Node graph | Taxonomy | `/taxonomy` | |
| 5 | Gear cog | Settings | `/settings` | Also active on About screen |

Active: icon + label in `--primary`. Inactive: `--muted`.
Bar bg: `--chrome`. Top border: 1px `--line`.

Platform chrome below the bar:
- **iOS**: 128×5px home indicator bar, 3px radius, 25% opacity `--fg`
- **Android**: 3 gesture buttons (back diamond, home circle, recents rect) in `--muted` at 60% opacity

---

## Data Model

```dart
enum ItemType { photo, video }
enum StorageSource { app, roll }
enum StorageMode { appOnly, rollOnly, both }
enum ThemePreference { light, dark, system }

class FieldItem {
  final String id;
  final String filePath;          // local file path OR asset ID
  final ItemType type;
  final StorageSource source;
  final DateTime capturedAt;
  final List<List<String>> tags;  // e.g. [["Animals","Birds","Raptors"]]
}

class TaxonomyNode {
  final String id;
  String name;
  List<TaxonomyNode> children;
}

class SearchHistoryEntry {
  final String id;
  final List<String> filterLabels;
  final DateTime searchedAt;
  final int resultCount;
}

class AppSettings {
  ThemePreference themeMode;
  String language;                // "en" | "de" | "it" | "fr"
  StorageMode storageMode;
}
```

---

## Storage & Camera Roll Behaviour

| Mode | Behaviour |
|---|---|
| **In-app only** | Files stored in app document directory. Can import from camera roll (copies). |
| **Camera roll** | Files stay on device roll. App stores metadata + tags only. Deleted roll items → auto-remove from FieldTaxa. |
| **Both** | Files saved to both. Roll items show green dot indicator. |

Monitor camera-roll deletions via `photo_manager`'s change notification API.

---

## Initial Taxonomy Tree (seed data)

```
Animals
  Insects
    Terrestrial
    Aquatic
      Insecta > Ephemeroptera > Baetidae > Baetis
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

Persist tree to local storage (Hive or SQLite). Apply changes immediately — no explicit "Save" step.

---

## Recommended Flutter Packages

| Package | Purpose |
|---|---|
| `go_router` | Declarative routing |
| `riverpod` or `flutter_bloc` | State management |
| `camera` | Live camera capture |
| `image_picker` | Camera roll import |
| `photo_manager` | Roll browsing + deletion monitoring |
| `cached_network_image` | Image caching (prototype) → `Image.file` (production) |
| `hive` or `sqflite` | Local persistence |
| `flutter_localizations` + `intl` | EN/DE/IT/FR |
| `google_fonts` | Plus Jakarta Sans + Newsreader |
| `path_provider` | App document directory |
| `video_player` | In-app video playback |

---

## Assets

| File | Usage |
|---|---|
| `uploads/MPeditechLogo.png` | Gallery header (44px height), About screen (52px height) |

The prototype uses remote placeholder images. In production replace with `Image.file` from local storage.

---

## Files in This Bundle

| File | Description |
|---|---|
| `README.md` | This document — full implementation spec |
| `FieldTaxa Reference.html` | Interactive HTML prototype — open in any browser |

---

## Notes for Claude Code

1. **Do not copy the HTML/JS prototype code** — recreate each screen as native Flutter widgets
2. The `T` object in the prototype JS contains all translated strings — use as basis for `.arb` localisation files
3. The `renderVals()` function in the JS shows the full state logic — reference for your state management
4. `GALLERY_CAP = 9` — photos shown per category in the main gallery view
5. The **iOS/Android toggle** in Settings is prototype-only — remove from the real app
6. Search runs entirely client-side — no network calls needed
7. For the taxonomy tree, persist changes immediately (no Save step)

---

*Design produced by MPediTech using Claude · June 2026*
