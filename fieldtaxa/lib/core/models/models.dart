import 'dart:convert';

enum ItemType { photo, video, obs }
enum StorageSource { app, roll }
enum StorageMode { appOnly, rollOnly, both }
enum ThemePreference { light, dark, system }
enum CoordSystem { gps, lv95 }
enum MapProvider { systemMaps, swisstopo }

class FieldItem {
  final String id;
  final String? filePath;
  final ItemType type;
  final StorageSource source;
  final DateTime capturedAt;
  final List<List<String>> tags;
  final double? lat;
  final double? lng;
  final bool isObsOnly;

  const FieldItem({
    required this.id,
    this.filePath,
    required this.type,
    required this.source,
    required this.capturedAt,
    required this.tags,
    this.lat,
    this.lng,
    this.isObsOnly = false,
  });

  String get topLevelCategory => tags.isNotEmpty && tags.first.isNotEmpty
      ? tags.first.first
      : '';

  String get lastTag {
    if (tags.isEmpty) return '';
    final flat = tags.first;
    return flat.isNotEmpty ? flat.last : '';
  }

  FieldItem copyWith({
    String? filePath,
    ItemType? type,
    StorageSource? source,
    DateTime? capturedAt,
    List<List<String>>? tags,
    double? lat,
    double? lng,
    bool? isObsOnly,
  }) {
    return FieldItem(
      id: id,
      filePath: filePath ?? this.filePath,
      type: type ?? this.type,
      source: source ?? this.source,
      capturedAt: capturedAt ?? this.capturedAt,
      tags: tags ?? this.tags,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      isObsOnly: isObsOnly ?? this.isObsOnly,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'file_path': filePath,
        'type': type.index,
        'source': source.index,
        'captured_at': capturedAt.toIso8601String(),
        'tags': jsonEncode(tags),
        'lat': lat,
        'lng': lng,
        'is_obs_only': isObsOnly ? 1 : 0,
      };

  factory FieldItem.fromMap(Map<String, dynamic> m) => FieldItem(
        id: m['id'] as String,
        filePath: m['file_path'] as String?,
        type: ItemType.values[m['type'] as int],
        source: StorageSource.values[m['source'] as int],
        capturedAt: DateTime.parse(m['captured_at'] as String),
        tags: (jsonDecode(m['tags'] as String) as List)
            .map((e) => (e as List).map((s) => s as String).toList())
            .toList(),
        lat: m['lat'] as double?,
        lng: m['lng'] as double?,
        isObsOnly: (m['is_obs_only'] as int) == 1,
      );
}

class Sighting {
  final String id;
  final String itemId;
  final DateTime observedAt;
  final double? lat;
  final double? lng;

  const Sighting({
    required this.id,
    required this.itemId,
    required this.observedAt,
    this.lat,
    this.lng,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'item_id': itemId,
        'observed_at': observedAt.toIso8601String(),
        'lat': lat,
        'lng': lng,
      };

  factory Sighting.fromMap(Map<String, dynamic> m) => Sighting(
        id: m['id'] as String,
        itemId: m['item_id'] as String,
        observedAt: DateTime.parse(m['observed_at'] as String),
        lat: m['lat'] as double?,
        lng: m['lng'] as double?,
      );
}

class TaxonomyNode {
  final String id;
  String name;
  String? parentId;
  int sortOrder;
  List<TaxonomyNode> children;

  TaxonomyNode({
    required this.id,
    required this.name,
    this.parentId,
    this.sortOrder = 0,
    this.children = const [],
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'parent_id': parentId,
        'sort_order': sortOrder,
      };

  factory TaxonomyNode.fromMap(Map<String, dynamic> m) => TaxonomyNode(
        id: m['id'] as String,
        name: m['name'] as String,
        parentId: m['parent_id'] as String?,
        sortOrder: m['sort_order'] as int? ?? 0,
      );

  List<String> get path {
    return [name];
  }
}

class SearchHistoryEntry {
  final String id;
  final List<String> filterLabels;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final DateTime searchedAt;
  final int resultCount;

  const SearchHistoryEntry({
    required this.id,
    required this.filterLabels,
    this.dateFrom,
    this.dateTo,
    required this.searchedAt,
    required this.resultCount,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'filter_labels': jsonEncode(filterLabels),
        'date_from': dateFrom?.toIso8601String(),
        'date_to': dateTo?.toIso8601String(),
        'searched_at': searchedAt.toIso8601String(),
        'result_count': resultCount,
      };

  factory SearchHistoryEntry.fromMap(Map<String, dynamic> m) =>
      SearchHistoryEntry(
        id: m['id'] as String,
        filterLabels: (jsonDecode(m['filter_labels'] as String) as List)
            .map((e) => e as String)
            .toList(),
        dateFrom: m['date_from'] != null
            ? DateTime.parse(m['date_from'] as String)
            : null,
        dateTo: m['date_to'] != null
            ? DateTime.parse(m['date_to'] as String)
            : null,
        searchedAt: DateTime.parse(m['searched_at'] as String),
        resultCount: m['result_count'] as int,
      );
}

class AppSettings {
  ThemePreference themeMode;
  String language;
  StorageMode storageMode;
  CoordSystem coordSystem;
  MapProvider mapProvider;

  AppSettings({
    this.themeMode = ThemePreference.system,
    this.language = 'en',
    this.storageMode = StorageMode.appOnly,
    this.coordSystem = CoordSystem.gps,
    this.mapProvider = MapProvider.systemMaps,
  });
}
