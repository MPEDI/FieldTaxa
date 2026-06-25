import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/models.dart';
import '../../core/providers/items_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/providers/taxonomy_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/coords.dart';

class ClassifyScreen extends ConsumerStatefulWidget {
  final String draftId;
  final String? filePath;
  final List<List<String>> initialTags;

  const ClassifyScreen({
    super.key,
    required this.draftId,
    this.filePath,
    required this.initialTags,
  });

  @override
  ConsumerState<ClassifyScreen> createState() => _ClassifyScreenState();
}

class _ClassifyScreenState extends ConsumerState<ClassifyScreen> {
  final List<List<String>> _tags = [];
  bool _browseMode = true; // false = find mode
  bool _gpsOn = false;
  double? _lat;
  double? _lng;
  final _searchCtrl = TextEditingController();

  // Browse tree breadcrumb
  TaxonomyNode? _drillParent;

  @override
  void initState() {
    super.initState();
    _tags.addAll(widget.initialTags);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleGps() async {
    if (_gpsOn) {
      setState(() {
        _gpsOn = false;
        _lat = null;
        _lng = null;
      });
      return;
    }
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _gpsOn = true;
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
    } catch (_) {
      // GPS not available in simulator — use placeholder
      setState(() {
        _gpsOn = true;
        _lat = 46.9521;
        _lng = 7.4482;
      });
    }
  }

  void _addTag(List<String> path) {
    if (!_tags.any((t) => t.join('/') == path.join('/'))) {
      setState(() => _tags.add(path));
    }
  }

  void _removeTag(int idx) => setState(() => _tags.removeAt(idx));

  Future<void> _save() async {
    final items = ref.read(itemsProvider.notifier);
    await items.addItem(
      filePath: widget.filePath,
      type: widget.filePath != null ? ItemType.photo : ItemType.obs,
      source: StorageSource.app,
      tags: _tags,
      lat: _lat,
      lng: _lng,
    );
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final tree = ref.watch(taxonomyProvider);

    return Scaffold(
      backgroundColor: context.appBg,
      appBar: AppBar(
        backgroundColor: context.appChrome,
        leading: TextButton(
          onPressed: () => context.pop(),
          child: Text('Cancel',
              style: jakartaStyle(13, context.appMuted)),
        ),
        leadingWidth: 80,
        title: Text('Classify',
            style: newsreaderStyle(17, context.appFg,
                weight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: context.appPrimary,
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: Text('Save',
                  style: jakartaStyle(13, Colors.white,
                      weight: FontWeight.w700)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // Preview + tags
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 84,
                  height: 84,
                  child: widget.filePath != null
                      ? Image.file(File(widget.filePath!),
                          fit: BoxFit.cover)
                      : Container(
                          color: context.appSurface2,
                          child: Icon(Icons.location_pin,
                              color: context.appMuted, size: 32),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ..._tags.asMap().entries.map((e) => _TagChip(
                          label: e.value.last,
                          onRemove: () => _removeTag(e.key),
                          context: context,
                        )),
                    if (_tags.isEmpty)
                      Text('No tags yet',
                          style: jakartaStyle(12, context.appMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Mode toggle
          Container(
            decoration: BoxDecoration(
              color: context.appSurface2,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ModeTab(
                    label: 'Browse tree',
                    active: _browseMode,
                    onTap: () => setState(() {
                      _browseMode = true;
                      _drillParent = null;
                    }),
                  ),
                ),
                Expanded(
                  child: _ModeTab(
                    label: 'Find',
                    active: !_browseMode,
                    onTap: () => setState(() => _browseMode = false),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // GPS toggle
          _GpsToggle(
            on: _gpsOn,
            lat: _lat,
            lng: _lng,
            coordSystem: settings.coordSystem,
            onToggle: _toggleGps,
          ),
          const SizedBox(height: 16),
          // Browse or Find
          if (_browseMode) ...[
            if (_drillParent != null) ...[
              // Breadcrumb
              GestureDetector(
                onTap: () => setState(() => _drillParent = null),
                child: Row(
                  children: [
                    Icon(Icons.arrow_back_ios_rounded,
                        size: 14, color: context.appPrimary),
                    Text('Back',
                        style: jakartaStyle(13, context.appPrimary,
                            weight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            // Node list
            ...(_drillParent != null
                    ? _drillParent!.children
                    : tree)
                .map((n) => _BrowseRow(
                      node: n,
                      onAdd: _addTag,
                      onDrill: (node) =>
                          setState(() => _drillParent = node),
                      getPath: (id) => ref
                          .read(taxonomyProvider.notifier)
                          .pathForId(id),
                    )),
          ] else ...[
            // Find mode
            TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search taxonomy…',
                hintStyle: jakartaStyle(13, context.appMuted),
                prefixIcon: Icon(Icons.search,
                    color: context.appMuted, size: 20),
                filled: true,
                fillColor: context.appSurface2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: jakartaStyle(13, context.appFg),
            ),
            const SizedBox(height: 8),
            ..._filteredNodes(tree, _searchCtrl.text)
                .map((n) => _FindRow(
                      node: n,
                      onAdd: _addTag,
                      getPath: (id) => ref
                          .read(taxonomyProvider.notifier)
                          .pathForId(id),
                    )),
          ],
        ],
      ),
    );
  }

  List<TaxonomyNode> _filteredNodes(List<TaxonomyNode> tree, String filter) {
    final flat = <TaxonomyNode>[];
    void walk(TaxonomyNode n) {
      flat.add(n);
      for (final c in n.children) walk(c);
    }
    for (final root in tree) walk(root);
    if (filter.isEmpty) return flat;
    return flat
        .where(
            (n) => n.name.toLowerCase().contains(filter.toLowerCase()))
        .toList();
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  final BuildContext context;

  const _TagChip(
      {required this.label,
      required this.onRemove,
      required this.context});

  @override
  Widget build(BuildContext _) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 6, 5),
      decoration: BoxDecoration(
        color: context.appTint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: jakartaStyle(12, context.appPrimary,
                  weight: FontWeight.w600)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 14, color: context.appPrimary),
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ModeTab(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? context.appSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Center(
          child: Text(label,
              style: jakartaStyle(
                  13, active ? context.appPrimary : context.appMuted,
                  weight:
                      active ? FontWeight.w700 : FontWeight.w500)),
        ),
      ),
    );
  }
}

class _GpsToggle extends StatelessWidget {
  final bool on;
  final double? lat;
  final double? lng;
  final CoordSystem coordSystem;
  final Future<void> Function() onToggle;

  const _GpsToggle({
    required this.on,
    this.lat,
    this.lng,
    required this.coordSystem,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    String coordStr = '';
    if (on && lat != null && lng != null) {
      if (coordSystem == CoordSystem.lv95) {
        final lv = wgsToLV95(lat!, lng!);
        coordStr = formatLV95(lv['E']!, lv['N']!);
      } else {
        coordStr = formatGps(lat!, lng!);
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: on ? context.appTint : context.appSurface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: on ? context.appPrimary : context.appLine,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_pin,
                  size: 16,
                  color: on ? context.appPrimary : context.appMuted),
              const SizedBox(width: 8),
              Text('GPS location',
                  style: jakartaStyle(13, context.appFg,
                      weight: FontWeight.w500)),
              const Spacer(),
              Switch.adaptive(
                value: on,
                onChanged: (_) => onToggle(),
                activeThumbColor: context.appPrimary,
              ),
            ],
          ),
          if (on && coordStr.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              coordStr,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: context.appFg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BrowseRow extends StatelessWidget {
  final TaxonomyNode node;
  final ValueChanged<List<String>> onAdd;
  final ValueChanged<TaxonomyNode> onDrill;
  final List<String> Function(String) getPath;

  const _BrowseRow({
    required this.node,
    required this.onAdd,
    required this.onDrill,
    required this.getPath,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          // + add button
          InkWell(
            onTap: () => onAdd(getPath(node.id)),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 32,
              height: 34,
              decoration: BoxDecoration(
                color: context.appTint,
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  Icon(Icons.add, size: 16, color: context.appPrimary),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(node.name,
                style:
                    jakartaStyle(13.5, context.appFg,
                        weight: FontWeight.w500)),
          ),
          if (node.children.isNotEmpty)
            InkWell(
              onTap: () => onDrill(node),
              child: Icon(Icons.chevron_right,
                  color: context.appMuted, size: 20),
            ),
        ],
      ),
    );
  }
}

class _FindRow extends StatelessWidget {
  final TaxonomyNode node;
  final ValueChanged<List<String>> onAdd;
  final List<String> Function(String) getPath;

  const _FindRow(
      {required this.node,
      required this.onAdd,
      required this.getPath});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          InkWell(
            onTap: () => onAdd(getPath(node.id)),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 32,
              height: 34,
              decoration: BoxDecoration(
                color: context.appTint,
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  Icon(Icons.add, size: 16, color: context.appPrimary),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(node.name,
                style: jakartaStyle(13.5, context.appFg,
                    weight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
