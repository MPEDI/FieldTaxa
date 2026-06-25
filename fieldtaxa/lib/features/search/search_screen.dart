import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/models.dart';
import '../../core/providers/items_provider.dart';
import '../../core/providers/taxonomy_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/photo_tile.dart';

const _uuid = Uuid();

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  final Set<String> _selectedNodeIds = {};
  DateTime? _from;
  DateTime? _to;
  bool _dateExpanded = false;
  List<FieldItem>? _results;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _run() {
    final allItems = ref.read(itemsProvider);
    final taxonomy = ref.read(taxonomyProvider.notifier);

    // Build set of all matching node names (selected + descendants)
    final matchingNames = <String>{};
    for (final id in _selectedNodeIds) {
      final path = taxonomy.pathForId(id);
      matchingNames.addAll(path);
      // Also add descendants
      _addDescendantNames(
          ref.read(taxonomyProvider), id, matchingNames, taxonomy);
    }

    var filtered = allItems;
    if (_selectedNodeIds.isNotEmpty) {
      filtered = filtered
          .where((item) =>
              item.tags.any((tagPath) =>
                  tagPath.any((t) => matchingNames.contains(t))))
          .toList();
    }
    if (_from != null) {
      filtered = filtered
          .where((item) => item.capturedAt.isAfter(
              _from!.subtract(const Duration(seconds: 1))))
          .toList();
    }
    if (_to != null) {
      filtered = filtered
          .where((item) => item.capturedAt
              .isBefore(_to!.add(const Duration(days: 1))))
          .toList();
    }

    setState(() => _results = filtered);

    // Save to history
    if (_selectedNodeIds.isNotEmpty || _from != null || _to != null) {
      final labels = _selectedNodeIds
          .map((id) => ref.read(taxonomyProvider.notifier).pathForId(id).last)
          .toList();
      ref.read(searchHistoryProvider.notifier).add(SearchHistoryEntry(
            id: _uuid.v4(),
            filterLabels: labels,
            dateFrom: _from,
            dateTo: _to,
            searchedAt: DateTime.now(),
            resultCount: filtered.length,
          ));
    }
  }

  void _addDescendantNames(List<TaxonomyNode> nodes, String parentId,
      Set<String> names, TaxonomyNotifier notifier) {
    for (final root in nodes) {
      _walkNode(root, parentId, names);
    }
  }

  void _walkNode(TaxonomyNode node, String targetParent, Set<String> names) {
    if (node.id == targetParent) {
      _collectAllNames(node, names);
    }
    for (final child in node.children) {
      _walkNode(child, targetParent, names);
    }
  }

  void _collectAllNames(TaxonomyNode node, Set<String> names) {
    names.add(node.name);
    for (final child in node.children) {
      _collectAllNames(child, names);
    }
  }

  bool _isDescendant(List<TaxonomyNode> flat, String id, String ancestorId) {
    return false; // simplified — full impl walks parent chain
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(searchHistoryProvider);
    final taxonomy = ref.watch(taxonomyProvider);

    return Scaffold(
      backgroundColor: context.appBg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Text('Search',
                      style: newsreaderStyle(24, context.appFg,
                          weight: FontWeight.w600)),
                ),
                const SizedBox(height: 14),
                // Search field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: TextField(
                    controller: _ctrl,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Filter by category',
                      hintStyle: jakartaStyle(13, context.appMuted),
                      prefixIcon:
                          Icon(Icons.search, color: context.appMuted, size: 20),
                      filled: true,
                      fillColor: context.appSurface2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                    style: jakartaStyle(13, context.appFg),
                  ),
                ),
                const SizedBox(height: 12),
                // Active filter chips
                if (_selectedNodeIds.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Wrap(
                      spacing: 6,
                      children: [
                        ..._selectedNodeIds.map((id) {
                          final label = ref
                              .read(taxonomyProvider.notifier)
                              .pathForId(id)
                              .last;
                          return Chip(
                            label: Text(label),
                            backgroundColor: context.appPrimary,
                            labelStyle:
                                jakartaStyle(12, Colors.white,
                                    weight: FontWeight.w600),
                            deleteIcon: const Icon(Icons.close, size: 14,
                                color: Colors.white70),
                            onDeleted: () =>
                                setState(() => _selectedNodeIds.remove(id)),
                          );
                        }),
                        TextButton(
                          onPressed: () => setState(() {
                            _selectedNodeIds.clear();
                            _from = null;
                            _to = null;
                            _results = null;
                          }),
                          child: Text('Clear',
                              style: jakartaStyle(12, context.appPrimary,
                                  weight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                // Date range
                _DateRangeSection(
                  expanded: _dateExpanded,
                  from: _from,
                  to: _to,
                  onToggle: () =>
                      setState(() => _dateExpanded = !_dateExpanded),
                  onFromChanged: (d) => setState(() => _from = d),
                  onToChanged: (d) => setState(() => _to = d),
                ),
                const SizedBox(height: 12),
                // Category list
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Text('Filter by category',
                      style: jakartaStyle(11, context.appMuted,
                          weight: FontWeight.w600)),
                ),
                const SizedBox(height: 8),
                _CategoryList(
                  nodes: taxonomy,
                  selected: _selectedNodeIds,
                  filter: _ctrl.text,
                  onToggle: (id) =>
                      setState(() => _selectedNodeIds.contains(id)
                          ? _selectedNodeIds.remove(id)
                          : _selectedNodeIds.add(id)),
                ),
                const SizedBox(height: 12),
                // Search button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _run,
                      style: FilledButton.styleFrom(
                        backgroundColor: context.appPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Search',
                          style: jakartaStyle(14, Colors.white,
                              weight: FontWeight.w700)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          // Results
          if (_results != null) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                child: Text('${_results!.length} results',
                    style: jakartaStyle(12, context.appMuted,
                        weight: FontWeight.w600)),
              ),
            ),
            if (_results!.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('No results found')),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 3,
                    crossAxisSpacing: 3,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => PhotoTile(item: _results![i]),
                    childCount: _results!.length,
                  ),
                ),
              ),
          ] else ...[
            // Search history
            if (history.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                  child: Text('Recent searches',
                      style: jakartaStyle(11, context.appMuted,
                          weight: FontWeight.w600)),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _HistoryRow(entry: history[i]),
                  childCount: history.length,
                ),
              ),
            ],
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _DateRangeSection extends StatelessWidget {
  final bool expanded;
  final DateTime? from;
  final DateTime? to;
  final VoidCallback onToggle;
  final ValueChanged<DateTime?> onFromChanged;
  final ValueChanged<DateTime?> onToChanged;

  const _DateRangeSection({
    required this.expanded,
    this.from,
    this.to,
    required this.onToggle,
    required this.onFromChanged,
    required this.onToChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasDate = from != null || to != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
      child: Column(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: context.appSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.appLine),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 16, color: context.appMuted),
                  const SizedBox(width: 8),
                  Text('Date range',
                      style: jakartaStyle(13, context.appFg,
                          weight: FontWeight.w500)),
                  if (hasDate) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: context.appTint,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text('Active',
                          style: jakartaStyle(10, context.appPrimary,
                              weight: FontWeight.w700)),
                    ),
                  ],
                  const Spacer(),
                  AnimatedRotation(
                    turns: expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 150),
                    child:
                        Icon(Icons.chevron_right, color: context.appMuted),
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: _DatePicker(
                        label: 'From',
                        value: from,
                        onChanged: onFromChanged)),
                const SizedBox(width: 8),
                Expanded(
                    child: _DatePicker(
                        label: 'To', value: to, onChanged: onToChanged)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DatePicker extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  const _DatePicker(
      {required this.label, this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        onChanged(d);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: context.appSurface2,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          value != null
              ? '${value!.day.toString().padLeft(2, '0')}.${value!.month.toString().padLeft(2, '0')}.${value!.year}'
              : label,
          style: jakartaStyle(
              13, value != null ? context.appFg : context.appMuted),
        ),
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  final List<TaxonomyNode> nodes;
  final Set<String> selected;
  final String filter;
  final ValueChanged<String> onToggle;

  const _CategoryList({
    required this.nodes,
    required this.selected,
    required this.filter,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    void walk(TaxonomyNode node, int depth) {
      if (filter.isNotEmpty &&
          !node.name.toLowerCase().contains(filter.toLowerCase())) {
        for (final c in node.children) walk(c, depth + 1);
        return;
      }
      rows.add(_CategoryRow(
        node: node,
        depth: depth,
        selected: selected.contains(node.id),
        onToggle: onToggle,
      ));
      if (filter.isEmpty) {
        for (final c in node.children) walk(c, depth + 1);
      }
    }

    for (final root in nodes) walk(root, 0);
    return Column(children: rows);
  }
}

class _CategoryRow extends StatelessWidget {
  final TaxonomyNode node;
  final int depth;
  final bool selected;
  final ValueChanged<String> onToggle;

  const _CategoryRow({
    required this.node,
    required this.depth,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onToggle(node.id),
      child: Padding(
        padding: EdgeInsets.fromLTRB(18.0 + depth * 14, 8, 18, 8),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: selected ? context.appPrimary : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? context.appPrimary
                      : context.appMuted,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Text(node.name,
                style: jakartaStyle(13, context.appFg,
                    weight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final SearchHistoryEntry entry;
  const _HistoryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final labels = entry.filterLabels.join(', ');
    final date =
        '${entry.searchedAt.day}.${entry.searchedAt.month}.${entry.searchedAt.year}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.appLine),
        ),
        child: Row(
          children: [
            Icon(Icons.history, size: 16, color: context.appMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(labels.isNotEmpty ? labels : 'All items',
                      style: jakartaStyle(13, context.appFg,
                          weight: FontWeight.w500)),
                  Text(date,
                      style: jakartaStyle(11, context.appMuted)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: context.appTint,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text('${entry.resultCount}',
                  style: jakartaStyle(11, context.appPrimary2,
                      weight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
