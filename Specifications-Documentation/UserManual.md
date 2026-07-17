# FieldTaxa — User Manual

**Version 1.0**  
**Developer:** MPediTech · www.mpeditech.com  
**Platforms:** iOS · Android

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [First Launch](#2-first-launch)
3. [Gallery](#3-gallery)
4. [Capturing a Photo or Video](#4-capturing-a-photo-or-video)
5. [Classifying an Observation](#5-classifying-an-observation)
6. [Photo Viewer](#6-photo-viewer)
7. [Logging Additional Sightings](#7-logging-additional-sightings)
8. [Editing Classification](#8-editing-classification)
9. [Deleting Observations and Sightings](#9-deleting-observations-and-sightings)
10. [Taxonomy Screen](#10-taxonomy-screen)
11. [Taxon Observations](#11-taxon-observations)
11a. [Distribution & Frequency](#11a-distribution--frequency)
12. [Search](#12-search)
13. [Map Overlay](#13-map-overlay)
14. [Settings](#14-settings)
15. [About](#15-about)
16. [Data & Privacy](#16-data--privacy)

---

## 1. Introduction

FieldTaxa is a field observation app designed for naturalists, ecologists, and anyone who records sightings of fauna, flora, or other taxa. The core workflow is simple:

1. **Capture** a photo (or import one from your camera roll), or log a GPS-only observation
2. **Classify** it by placing it in your personal taxonomy tree
3. **Track sightings** — log each time and place you encounter that organism again, without needing to take a new photo

All data is stored locally on your device. No account or internet connection is required to use the app (an internet connection is only needed to display Swisstopo map tiles).

---

## 2. First Launch

On first launch the app creates a default taxonomy tree containing:

```
Animalia
  Insecta
    Coleoptera
    Diptera
    Ephemeroptera
  Aves
    Falconiformes
    Passeriformes
  Amphibia
  Mammalia
Plantae
  Pteridophyta
  Gymnospermae
  Angiospermae
    Monocotyledonae
    Dicotyledonae
Incertae sedis
```

You can rename, extend, or delete any of these categories at any time from the **Taxonomy** tab.

The app opens on the **Gallery** tab, which will be empty until you add your first observation.

---

## 3. Gallery

The Gallery is the home screen. It groups all your observations by their top-level taxonomy category.

### Layout

- **Header:** Shows the app name and your total observation count.
- **Category sections:** Each top-level category has a heading, a count badge, and a grid of up to 9 photo tiles.
- **"See all N →" row:** Appears below the 9-tile grid when a category contains more than 9 items. Tap it to open the full grid for that category.

### Photo Tiles

Each tile shows:
- The photo (or a map-pin icon for GPS-only observations)
- The innermost taxonomy label at the bottom-left (e.g. "Coleoptera")
- A small play icon badge (top-right) if the item is a video
- A green dot (top-left) if the photo was imported from your camera roll

**Tap any tile** to open the **Photo Viewer**.

### Category Drill-Down

Tapping "See all →" opens a full-screen 3-column grid of all items in that category. Tap the **← Gallery** button in the top-left to return.

---

## 4. Capturing a Photo or Video

Tap the **camera FAB** (the large green circle button) in the bottom navigation bar. A sheet slides up with four options:

| Option | Action |
|---|---|
| **Take Photo** | Opens the system camera for a still photo |
| **Choose from Library** | Opens the photo library picker |
| **Record Video** | Opens the system camera in video mode |
| **Choose Video** | Opens the video library picker |

Tap the option you need. The system camera or picker opens immediately; after capturing or selecting, the app navigates automatically to the **Classify** screen.

---

## 5. Classifying an Observation

The Classify screen appears after every capture or import. Here you assign taxonomy tags and optionally record a GPS position.

### Preview Thumbnail

The image you captured or imported is shown as an 84×84 dp thumbnail on the left. For GPS-only observations, a map-pin placeholder is shown.

### Entering a Species

A **Type a species name…** field is shown above the Browse / Find tabs. **Typing never contacts the internet** — nothing is searched automatically as you type.

You then have two ways to add the species:

**1. Add directly (no search, works offline).** As soon as you type a name, an **Add "…" directly (no search)** row appears below the field. Tap it — or simply press **Return** on the keyboard — to add the typed name as-is. The species is placed under **Incertae sedis** ("of uncertain placement") in your taxonomy tree; you can later move it to the correct branch from the Taxonomy screen (see §10, *Moving a Category*).

**2. Search online (GBIF), optional.** If you want the full scientific hierarchy filled in for you, tap the **globe icon** on the right of the field. Only then does the app query the [GBIF](https://www.gbif.org) biodiversity database and show matching species with their taxonomy breadcrumb. Tap any result to:
1. Automatically create any missing taxonomy nodes (Kingdom → Phylum → Class → Order → Family → Genus → Species) in your local taxonomy tree.
2. Add the full taxonomy path as a tag on the observation.

> An internet connection is required only for the GBIF globe-icon look-up. Everything else — including direct add — works fully offline.

### Adding Tags Manually

Tags represent the taxonomy paths that describe your observation. A single item can have multiple tags (e.g. if you are unsure about the exact classification).

**Browse Tree mode** (default):
- The taxonomy tree is shown as a node list.
- Tap a node's **›** (chevron) to drill into its children.
- Tap the **← Back** button to navigate back up.
- Tap the **+** button to the left of any node name to add that full taxonomy path as a tag.

**Find mode** (tap "Find" in the toggle at the top):
- Type a name in the search field to filter the taxonomy list.
- Tap the **+** button next to any result to add it as a tag.

**Removing a tag:** Tap the **✕** on any tag chip at the top of the screen.

### GPS Position

When the Classify screen opens, the app automatically acquires your current GPS position. Two editable coordinate fields appear showing the position in the format selected in Settings (GPS or Swiss LV95).

- **Edit manually**: Tap either field and type a value to override the GPS position. In LV95 mode the fields are labelled **E** and **N**; in GPS mode they are **Latitude** and **Longitude**.
- **Re-fetch**: Tap the **crosshair icon** (to the left of the toggle) to replace the current values with a fresh GPS reading.
- **Disable**: Tap the toggle to turn GPS off entirely and save the observation without coordinates.

> GPS is always recorded automatically. The editable fields let you correct the position when needed (e.g. if you are indoors or want to enter an exact reference point).

### Saving

Tap **Save** (top-right) to save the observation. The app returns to the Gallery and the new item appears under its category.

Tap **Cancel** (top-left) to discard and return to the Gallery without saving.

---

## 6. Photo Viewer

Tap any photo tile to open the full-screen Photo Viewer.

### What You See

- **The photo** fills the screen (pinch to zoom, swipe to pan)
- **Tag chips** at the bottom show the taxonomy paths assigned to this item — one chip per classification, with the **species name first** (bold) followed by the higher-level ranks in ascending order (e.g. *Carabus auratus · Carabidae › Coleoptera › Insecta › Animalia*). Duplicate classifications are shown only once.
- **Coordinate row**: shows the recorded position (or "No position" if none). Tap the coordinate text to open the **Map Overlay**.
- **Position button** (next to the coordinate row): tap **Position** to open the Edit Position sheet (see §6.1)
- **Camera roll banner** (if the item was imported from the camera roll)
- **Log sighting button**: tap to log a new sighting for this item (see §7)
- **Edit button** (top-right of the tags row): tap to edit the classification (see §8)
- **✕ button** (top-right): close the viewer and return to the previous screen

### 6.1 Editing the Position

Tap the **Position** button at any time to correct or add a GPS position to an observation.

The **Edit position** sheet shows two editable fields with the current coordinates in your preferred format (E/N for Swiss LV95, or Latitude/Longitude for GPS).

| Control | Action |
|---|---|
| **E / N** or **Lat / Lng** fields | Type a value directly to set or correct the position |
| **Fetch GPS** | Replaces both fields with your current device location |
| **Clear position** | Removes all coordinates from the observation |
| **Save position** | Persists the values and closes the sheet |

The coordinate row in the viewer updates immediately after saving.

---

## 7. Logging Additional Sightings

A **sighting** is a dated record of when you encountered an organism — separate from the original capture. For example, if you photographed a beetle in April and saw it again in June, you can log the June encounter without importing a new photo.

### How to Log a Sighting

1. Open the **Photo Viewer** for the relevant item.
2. Tap **Log sighting** at the bottom of the screen. The sighting count badge shows how many sightings are already recorded.
3. In the **Log sighting** sheet:
   - **Date / time:** Tap the date field to adjust the date. The time is set automatically to the current time; tap the date field and modify the time as needed.
   - **GPS location:** Toggle on to record your current GPS position for this sighting. Toggle off to leave the location blank.
4. Tap **Save sighting** to record it.

The sighting count badge on the "Log sighting" button updates immediately. All sightings are visible in the **Taxon Observations** screen for the relevant node.

### GPS-Only Observations (No Photo)

From the **Taxon Observations** screen (§10), tap **Add observation (no photo)** to create an item with only a GPS position and the current timestamp — no image needed. This is useful when you want to log a location where you observed a taxon without taking a photo.

---

## 8. Editing Classification

You can always change an item's taxonomy tags after the initial classify step.

1. Open the **Photo Viewer** for the item.
2. Tap the **Edit** button (top-right of the tag chips row).
3. The **Edit classification** sheet slides up. It contains:
   - All current tag chips (tap **✕** on any chip to remove it)
   - A **Type a species name…** field — typing never searches online. Press **Return** or tap the **Add "…" directly** row to add the name offline (placed under *Incertae sedis*); or tap the **globe icon** to look the species up on GBIF and pull in its full taxonomy path
   - **Browse tree / Find** tabs for selecting from your local taxonomy tree
4. Add tags using the **+** buttons in Browse or Find mode, via the GBIF globe icon, or via direct add. Duplicate entries are removed automatically when you save.
5. Tap **Save** to apply the changes, or **Cancel** to discard.

The sheet is scrollable and opens at full height so the taxonomy tree is fully accessible.

---

## 9. Deleting Observations and Sightings

### Deleting an Observation (item + all its sightings)

An observation can be deleted from two places:

**From the Photo Viewer:**
1. Open the observation by tapping its tile in the Gallery, Category, or Taxon Observations screen.
2. Tap the **red trash icon** in the top-left corner of the viewer.
3. Confirm the deletion in the dialog that appears.

The observation, its media file, and all associated sightings are permanently removed.

**From the Taxon Observations screen:**
1. Navigate to **Taxonomy → [node name]** to open the Taxon Observations list.
2. Tap the **small delete icon** (trash, red) at the right end of any observation card header.
3. Confirm the deletion in the dialog.

### Deleting a Single Sighting

Individual sightings can be deleted from the **Taxon Observations** screen without removing the observation itself:

1. Navigate to **Taxonomy → [node name]**.
2. Locate the observation and find the sighting sub-row you want to remove.
3. Tap the **× button** on the right side of the sighting row.
4. Confirm the deletion.

The observation and all other sightings remain unaffected.

> **Note:** Deletion is permanent and cannot be undone.

---

## 10. Taxonomy Screen

Tap the **Taxonomy** tab in the bottom navigation bar.

The Taxonomy screen shows the full taxonomy tree with a collapse/expand control for each branch. Every node displays a badge showing the **total number of sightings** across all items classified under that node or any of its descendants.

### Expanding / Collapsing Nodes

Tap the **›** chevron to the left of any node name to expand or collapse its children. The chevron rotates 90° when expanded.

### Navigating to Observations

Tap a **node name** to open the **Taxon Observations** screen (§10) for that node.

### Adding a Child Category

Tap the **+** button (small square, right side of a row) to add a new child category under that node. A dialog appears to enter the name. Tap **Add** to confirm.

### Moving a Category (Rearranging the Tree)

If a species or category was inserted in the wrong branch, you can move it:

1. Tap the **move icon** (folder with arrow, right side of the row, between **+** and the trash icon).
2. A sheet opens listing **Top level (root)** and every other category in the tree (indented to show hierarchy). The current parent is greyed out and marked *current*; a category can never be moved into its own subtree.
3. Tap the destination. The category — including all its child categories — is re-parented immediately.

**All observations tagged under the moved category are updated automatically**: their classification paths are rewritten to reflect the new position in the tree, so nothing gets lost or misfiled.

### Adding a Root-Level Category

Tap the **Add category** button at the bottom of the tree (dashed border) to add a new top-level category.

### Deleting a Category

Tap the **trash** icon (red, right side of a row) to delete a category. A confirmation dialog warns that all child categories will also be deleted. Tap **Delete** to confirm.

> Deleting a category does not delete the observations tagged to it — those items remain in your library, simply without a category tag.

---

## 11. Taxon Observations

The Taxon Observations screen shows all items classified under a specific taxonomy node or any of its descendants.

**Access:** Tap a node name in the Taxonomy screen.

### Header

- **Node name** is shown as the screen title.
- A **sighting count badge** (top-right) shows the total number of sightings across all matching items.

### Stats Bar

Three statistics are displayed:

| Stat | Meaning |
|---|---|
| First obs. | Date of the earliest captured item |
| Last obs. | Date of the most recent captured item |
| Locations | Number of sightings that have a GPS position |

### Observation List

Each item appears as a card with:
- **Thumbnail** (58×58 dp) — the actual photo, or a map-pin icon for GPS-only items
- **Taxonomy label** — the innermost tag of the item
- **Date** — the capture date
- **Sighting count** badge — number of logged sightings (e.g. "3×")
- **Sighting sub-rows** — each logged sighting appears indented below the item card, showing:
  - Date and time
  - GPS coordinate (formatted per your coordinate setting) — tap to open the **Map Overlay**
  - An external-link icon when a location is available

**Tap the item row** to open the **Photo Viewer** for that item.

### Adding an Observation Without a Photo

Tap **Add observation (no photo)** at the top to create a GPS-only item tagged to this node. The current timestamp and GPS position are recorded automatically.

### Distribution & Frequency

Tap the **chart icon** (📈, top-right of the Taxon Observations screen) to open the **Distribution** screen for that taxon — see §11a.

---

## 11a. Distribution & Frequency

This screen shows **where** a taxon has been observed and **how often**. It covers the selected node and everything below it in the tree, so opening it on *Insecta* summarises every beetle, fly and mayfly beneath it.

**Access:** Taxonomy → *[node name]* → the **chart icon** in the top-right.

### Header

Below the taxon name a summary line reads: total sightings · how many are georeferenced · how many distinct locations.

### Geographic Distribution

A map plots every georeferenced sighting. The view **automatically zooms and centres** to fit all points.

- **Marker size reflects frequency** — sightings within about 11 m of each other are grouped into one circle, and the circle's area grows with the number of sightings there. Circles with more than one sighting show the count.
- The badge in the section header shows which map source is in use — **Swisstopo** or **System maps** — following your choice in **Settings → Maps** (§14):
  - **Swisstopo:** official Swiss national map tiles are drawn behind the markers (requires internet).
  - **System maps:** a neutral grid is drawn instead of tiles. Marker positions use the same projection, so the spatial pattern remains accurate; tap **Open in maps** to view the area in Apple/Google Maps.
- **Open in maps** opens the centre of the distribution in `map.geo.admin.ch` (Swisstopo) or the system maps app.

If no sighting has a GPS position, the map area shows *No georeferenced sightings* instead.

### Observation Frequency

Two bar charts summarise when the taxon was seen. Each bar is labelled with its count; empty periods keep a thin baseline stub.

| Chart | Meaning |
|---|---|
| **By month (all years)** | Sightings per calendar month (J–D), pooled across all years — reveals the seasonal pattern. The peak month is highlighted in the full accent colour. |
| **By year** | Sightings per year, oldest to newest — reveals the recording trend. |

> Frequency is based on **sightings**, not photos: each time you log an encounter (§7) it counts, so a single photographed individual seen five times contributes five records.

---

## 12. Search

Tap the **Search** tab in the bottom navigation bar.

The Search screen lets you filter your observations by taxonomy category and/or date range.

### Filtering by Category

A checklist of all taxonomy nodes (indented to reflect the tree hierarchy) is shown. Tap any node to select it — a filled checkbox indicates the selection. Selected nodes appear as removable chips above the checklist.

The search matches items tagged with any of the selected nodes or their descendants.

### Filtering by Date Range

Tap the **Date range** row to expand the date picker:
- **From:** Tap to choose the start date.
- **To:** Tap to choose the end date.

An **Active** badge appears on the Date range row when dates are set. Tap the row again to collapse.

### Running a Search

Tap the **Search** button (full-width, green). Results appear as a 3-column photo grid above the filter controls. The result count is shown above the grid.

Tap **Clear** (appears when any filter is active) to reset all filters and dismiss the results.

### Search History

When no search results are visible, up to 20 recent searches are listed below the filters. Each row shows:
- The category labels used
- The search date
- The result count

**Tap any history row** to restore those exact filters and re-run the search immediately.

---

## 13. Map Overlay

The Map Overlay is a bottom sheet that shows the GPS position of an observation or sighting on a map.

**Access:** Tap any coordinate row in the Photo Viewer or in a Taxon Observations sighting sub-row.

### Swisstopo Mode

When **Swisstopo** is selected in Settings > Maps, a 3×3 grid of Swisstopo WMTS tiles at zoom level 15 is displayed with a green crosshair centred on the coordinate. An internet connection is required to load the tiles.

### System Maps Mode

When **System maps** is selected, a placeholder is shown with the coordinate. Tap **Open in …** to open the coordinate in Apple Maps (iOS) or Google Maps (Android).

### Opening Externally

- **Swisstopo web:** Opens `map.geo.admin.ch` centred on the LV95 coordinate.
- **Apple Maps (iOS):** Opens the location in the system Maps app.
- **Google Maps (Android):** Opens the location in Google Maps.

Dismiss the overlay by swiping down or tapping the **✕** button.

---

## 14. Settings

Tap the **Settings** tab in the bottom navigation bar.

### Language

Choose between **English**, **Deutsch**, **Italiano**, or **Français**. The change takes effect immediately.

### Appearance

Choose **Light**, **Dark**, or **System** (follows your device's system setting). The change takes effect immediately.

### Storage Library

Choose how captured media is saved:

| Option | Behaviour |
|---|---|
| **In-app only** | Media is stored inside the app's private storage and does not appear in the camera roll |
| **Camera roll** | Media is saved to the device camera roll in addition to app storage |
| **Both** | Media is saved to both locations simultaneously |

> The storage mode affects new captures only. Existing items are not moved.

### Coordinates

Choose how GPS coordinates are displayed throughout the app:

| Option | Format example |
|---|---|
| **GPS** | `46.9521° N  7.4482° E` |
| **Swiss LV95** | `E 2'600'072  N 1'200'147` |

> Swiss LV95 is only accurate for coordinates within Switzerland. Coordinates outside Swiss territory may be inaccurate when converted to LV95.

### Maps

Choose the map provider used by the **Map Overlay** (§13) and the **Distribution** screen (§11a):

| Option | Description |
|---|---|
| **System maps** | Uses Apple Maps (iOS) or Google Maps (Android) when opening a location externally; the Distribution map draws markers on a neutral grid |
| **Swisstopo** | Displays official Swiss national map tiles behind the markers (requires internet) |

---

## 15. About

From **Settings**, tap **About** at the bottom of the list.

The About screen shows:
- The MPediTech logo and the FieldTaxa app name
- App version, build number, and release date
- Developer name and website link

Tap **www.mpeditech.com/en/fieldtaxa** to open the FieldTaxa page on the MPediTech website in your browser.

---

## 16. Data & Privacy

- **Local storage only.** All your observations, taxonomy, and settings are stored on your device using a local SQLite database. No data is sent to any server.
- **Location data.** GPS coordinates are stored locally alongside each observation or sighting. Location access is requested only when you tap a GPS toggle; the app never accesses location in the background.
- **Camera & Photos.** Camera and photo library access is requested only when you open the Capture screen. No images are uploaded or shared without your explicit action.
- **Internet.** An internet connection is used only to load Swisstopo map tiles in the Map Overlay. No personal data is transmitted.
- **No account required.** FieldTaxa works entirely offline and does not require registration or an account.

---

*FieldTaxa · © 2026 MPediTech · www.mpeditech.com*
