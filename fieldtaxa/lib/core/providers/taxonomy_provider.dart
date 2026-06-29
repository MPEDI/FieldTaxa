import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../db/database_helper.dart';
import '../models/models.dart';

const _uuid = Uuid();

class TaxonomyNotifier extends StateNotifier<List<TaxonomyNode>> {
  TaxonomyNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('taxonomy_nodes', orderBy: 'sort_order ASC');
    if (rows.isEmpty) {
      await _seed();
    } else {
      state = _buildTree(rows.map(TaxonomyNode.fromMap).toList());
    }
  }

  Future<void> _seed() async {
    final seeds = _defaultTaxonomy();
    final db = await DatabaseHelper.instance.database;
    final batch = db.batch();
    for (final n in seeds) {
      batch.insert('taxonomy_nodes', n.toMap());
    }
    await batch.commit(noResult: true);
    state = _buildTree(seeds);
  }

  List<TaxonomyNode> _buildTree(List<TaxonomyNode> flat) {
    final map = {for (final n in flat) n.id: n};
    final roots = <TaxonomyNode>[];
    for (final n in flat) {
      n.children = [];
    }
    for (final n in flat) {
      if (n.parentId == null) {
        roots.add(n);
      } else {
        map[n.parentId]?.children.add(n);
      }
    }
    return roots;
  }

  Future<void> addNode(String name, String? parentId) async {
    final node = TaxonomyNode(
      id: _uuid.v4(),
      name: name,
      parentId: parentId,
      sortOrder: DateTime.now().millisecondsSinceEpoch,
    );
    final db = await DatabaseHelper.instance.database;
    await db.insert('taxonomy_nodes', node.toMap());
    await _load();
  }

  Future<void> renameNode(String id, String name) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('taxonomy_nodes', {'name': name},
        where: 'id = ?', whereArgs: [id]);
    await _load();
  }

  Future<void> deleteNode(String id) async {
    final db = await DatabaseHelper.instance.database;
    // Collect all descendant ids
    final allIds = <String>[id];
    final rows = await db.query('taxonomy_nodes');
    final flat = rows.map(TaxonomyNode.fromMap).toList();
    _collectDescendants(flat, id, allIds);
    final batch = db.batch();
    for (final nodeId in allIds) {
      batch.delete('taxonomy_nodes', where: 'id = ?', whereArgs: [nodeId]);
    }
    await batch.commit(noResult: true);
    await _load();
  }

  void _collectDescendants(
      List<TaxonomyNode> flat, String parentId, List<String> result) {
    for (final n in flat) {
      if (n.parentId == parentId) {
        result.add(n.id);
        _collectDescendants(flat, n.id, result);
      }
    }
  }

  /// Ensures every name in [names] exists in the taxonomy tree (creating missing
  /// nodes under the correct parent) and returns the names list for use as a tag path.
  Future<List<String>> ensurePath(List<String> names) async {
    if (names.isEmpty) return [];
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('taxonomy_nodes');
    final flat = rows.map(TaxonomyNode.fromMap).toList();

    String? parentId;
    bool changed = false;

    for (final name in names) {
      // Case-insensitive search for an existing node under the current parent
      TaxonomyNode? existing;
      for (final n in flat) {
        if (n.parentId == parentId &&
            n.name.toLowerCase() == name.toLowerCase()) {
          existing = n;
          break;
        }
      }

      if (existing != null) {
        parentId = existing.id;
      } else {
        final newId = _uuid.v4();
        final node = TaxonomyNode(
          id: newId,
          name: name,
          parentId: parentId,
          sortOrder: DateTime.now().millisecondsSinceEpoch,
        );
        await db.insert('taxonomy_nodes', node.toMap());
        flat.add(node);
        parentId = newId;
        changed = true;
      }
    }

    if (changed) await _load();
    return names;
  }

  List<TaxonomyNode> get flatList {
    final result = <TaxonomyNode>[];
    void walk(List<TaxonomyNode> nodes) {
      for (final n in nodes) {
        result.add(n);
        walk(n.children);
      }
    }

    walk(state);
    return result;
  }

  /// Returns the full path for a node id (e.g. ["Animals", "Birds", "Raptors"])
  List<String> pathForId(String id) {
    final flat = flatList;
    final map = {for (final n in flat) n.id: n};
    final path = <String>[];
    TaxonomyNode? cur = map[id];
    while (cur != null) {
      path.insert(0, cur.name);
      cur = cur.parentId != null ? map[cur.parentId] : null;
    }
    return path;
  }
}

final taxonomyProvider =
    StateNotifierProvider<TaxonomyNotifier, List<TaxonomyNode>>(
        (_) => TaxonomyNotifier());

List<TaxonomyNode> _defaultTaxonomy() {
  int order = 0;
  TaxonomyNode n(String id, String name, String? parentId) =>
      TaxonomyNode(id: id, name: name, parentId: parentId, sortOrder: order++);

  return [
    // Animalia
    n('animalia', 'Animalia', null),
    n('insecta', 'Insecta', 'animalia'),
    n('coleoptera', 'Coleoptera', 'insecta'),
    n('diptera', 'Diptera', 'insecta'),
    n('ephemeroptera', 'Ephemeroptera', 'insecta'),
    n('aves', 'Aves', 'animalia'),
    n('falconiformes', 'Falconiformes', 'aves'),
    n('passeriformes', 'Passeriformes', 'aves'),
    n('amphibia', 'Amphibia', 'animalia'),
    n('mammalia', 'Mammalia', 'animalia'),
    // Plantae
    n('plantae', 'Plantae', null),
    n('pteridophyta', 'Pteridophyta', 'plantae'),
    n('gymnospermae', 'Gymnospermae', 'plantae'),
    n('angiospermae', 'Angiospermae', 'plantae'),
    n('monocotyledonae', 'Monocotyledonae', 'angiospermae'),
    n('dicotyledonae', 'Dicotyledonae', 'angiospermae'),
    // Unclassified
    n('incertae_sedis', 'Incertae sedis', null),
  ];
}
