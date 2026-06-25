import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../db/database_helper.dart';
import '../models/models.dart';

const _uuid = Uuid();

class ItemsNotifier extends StateNotifier<List<FieldItem>> {
  ItemsNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('field_items', orderBy: 'captured_at DESC');
    state = rows.map(FieldItem.fromMap).toList();
  }

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
    final item = FieldItem(
      id: _uuid.v4(),
      filePath: filePath,
      type: type,
      source: source,
      capturedAt: capturedAt ?? DateTime.now(),
      tags: tags,
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
    await db.update('field_items', {'tags': jsonEncode(tags)},
        where: 'id = ?', whereArgs: [id]);
    await _load();
  }

  Future<void> deleteItem(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('field_items', where: 'id = ?', whereArgs: [id]);
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
