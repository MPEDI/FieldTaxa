import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../db/database_helper.dart';
import '../models/models.dart';

const _uuid = Uuid();

/// Copies [sourcePath] into the app's permanent photos directory.
/// Returns the new persistent path, or null if sourcePath is null.
Future<String?> _persistFile(String? sourcePath, String itemId) async {
  if (sourcePath == null) return null;
  final docsDir = await getApplicationDocumentsDirectory();
  final photosDir = Directory(p.join(docsDir.path, 'fieldtaxa_photos'));
  if (!photosDir.existsSync()) photosDir.createSync(recursive: true);
  final ext = p.extension(sourcePath).isNotEmpty ? p.extension(sourcePath) : '.jpg';
  final dest = p.join(photosDir.path, '$itemId$ext');
  await File(sourcePath).copy(dest);
  return dest;
}

/// Removes duplicate tag paths (same full path listed twice).
List<List<String>> _dedupeTags(List<List<String>> tags) {
  final seen = <String>{};
  return tags.where((t) => seen.add(t.join('/'))).toList();
}

class ItemsNotifier extends StateNotifier<List<FieldItem>> {
  ItemsNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('field_items', orderBy: 'captured_at DESC');
    state = rows.map(FieldItem.fromMap).toList();
  }

  /// Re-reads all items from the database (e.g. after a taxonomy move
  /// rewrote tag paths).
  Future<void> reload() => _load();

  Future<FieldItem> addItem({
    String? filePath,
    required ItemType type,
    required StorageSource source,
    required List<List<String>> tags,
    double? lat,
    double? lng,
    bool isObsOnly = false,
    DateTime? capturedAt,
  }) async {
    final id = _uuid.v4();
    // Copy the file to a persistent location before saving the path to DB.
    // image_picker returns paths inside the OS temp directory which can be
    // cleared between sessions, causing photos to disappear on real devices.
    final persistedPath = await _persistFile(filePath, id);

    final item = FieldItem(
      id: id,
      filePath: persistedPath,
      type: type,
      source: source,
      capturedAt: capturedAt ?? DateTime.now(),
      tags: _dedupeTags(tags),
      lat: lat,
      lng: lng,
      isObsOnly: isObsOnly,
    );
    final db = await DatabaseHelper.instance.database;
    await db.insert('field_items', item.toMap());
    await _addSighting(item.id, item.capturedAt, lat, lng);
    await _load();
    return item;
  }

  Future<void> updateTags(String id, List<List<String>> tags) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('field_items', {'tags': jsonEncode(_dedupeTags(tags))},
        where: 'id = ?', whereArgs: [id]);
    await _load();
  }

  Future<void> updateCoords(String id, double? lat, double? lng) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'field_items',
      {'lat': lat, 'lng': lng},
      where: 'id = ?',
      whereArgs: [id],
    );
    await _load();
  }

  /// Deletes the item from the database (sightings cascade via FK),
  /// removes the associated media file if it exists, and reloads state.
  Future<void> deleteItem(String id, {String? filePath}) async {
    final db = await DatabaseHelper.instance.database;
    // Cascade delete of sightings is handled by the DB FK (foreign_keys ON).
    await db.delete('field_items', where: 'id = ?', whereArgs: [id]);
    // Delete the media file from persistent storage.
    if (filePath != null) {
      try {
        final f = File(filePath);
        if (f.existsSync()) f.deleteSync();
      } catch (_) {}
    }
    await _load();
  }

  Future<void> _addSighting(
      String itemId, DateTime at, double? lat, double? lng) async {
    final sighting = Sighting(
      id: _uuid.v4(),
      itemId: itemId,
      observedAt: at,
      lat: lat,
      lng: lng,
    );
    final db = await DatabaseHelper.instance.database;
    await db.insert('sightings', sighting.toMap());
  }

  Map<String, List<FieldItem>> get groupedByTopCategory {
    final map = <String, List<FieldItem>>{};
    for (final item in state) {
      final cat = item.topLevelCategory;
      if (cat.isEmpty) continue;
      map.putIfAbsent(cat, () => []).add(item);
    }
    return map;
  }
}

final itemsProvider =
    StateNotifierProvider<ItemsNotifier, List<FieldItem>>(
        (_) => ItemsNotifier());

class SightingsNotifier extends StateNotifier<List<Sighting>> {
  SightingsNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('sightings', orderBy: 'observed_at DESC');
    state = rows.map(Sighting.fromMap).toList();
  }

  Future<void> addSighting(
      String itemId, DateTime at, double? lat, double? lng) async {
    final sighting = Sighting(
      id: _uuid.v4(),
      itemId: itemId,
      observedAt: at,
      lat: lat,
      lng: lng,
    );
    final db = await DatabaseHelper.instance.database;
    await db.insert('sightings', sighting.toMap());
    await _load();
  }

  Future<void> deleteSighting(String sightingId) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('sightings', where: 'id = ?', whereArgs: [sightingId]);
    await _load();
  }

  Future<void> reload() => _load();

  List<Sighting> forItem(String itemId) =>
      state.where((s) => s.itemId == itemId).toList();
}

final sightingsProvider =
    StateNotifierProvider<SightingsNotifier, List<Sighting>>(
        (_) => SightingsNotifier());

class SearchHistoryNotifier extends StateNotifier<List<SearchHistoryEntry>> {
  SearchHistoryNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('search_history',
        orderBy: 'searched_at DESC', limit: 20);
    state = rows.map(SearchHistoryEntry.fromMap).toList();
  }

  Future<void> add(SearchHistoryEntry entry) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('search_history', entry.toMap());
    await _load();
  }
}

final searchHistoryProvider =
    StateNotifierProvider<SearchHistoryNotifier, List<SearchHistoryEntry>>(
        (_) => SearchHistoryNotifier());
