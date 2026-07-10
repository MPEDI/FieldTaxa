import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/models.dart';
import '../../core/providers/items_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/providers/taxonomy_provider.dart';
import '../../core/services/gbif_service.dart';
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
  bool _browseMode = true;
  bool _gpsOn = false;
  double? _lat;
  double? _lng;

  // Coordinate text controllers (display in user's preferred system)
  final _coord1Ctrl = TextEditingController(); // Lat or E
  final _coord2Ctrl = TextEditingController(); // Lng or N

  // Browse tree
  TaxonomyNode? _drillParent;
  final _searchCtrl = TextEditingController();

  // GBIF species search
  final _speciesCtrl = TextEditingController();
  List<GbifSuggestion> _gbifSuggestions = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tags.addAll(widget.initialTags);
    // Auto-fetch GPS on every capture/import — location is always recorded.
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchGps());
  }

  @override
  void dispose() {
    _coord1Ctrl.dispose();
    _coord2Ctrl.dispose();
    _searchCtrl.dispose();
    _speciesCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ─── GPS ────────────────────────────────────────────────────────────────────

  Future<void> _fetchGps() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        perm = await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      _updateCoordsFromWgs(pos.latitude, pos.longitude);
      setState(() {
        _gpsOn = true;
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
    } catch (_) {
      // GPS unavailable (simulator / permission denied) — keep off
      if (mounted) setState(() => _gpsOn = false);
    }
  }

  void _updateCoordsFromWgs(double lat, double lng) {
    final settings = ref.read(settingsProvider);
    if (settings.coordSystem == CoordSystem.lv95) {
      final lv = wgsToLV95(lat, lng);
      _coord1Ctrl.text = lv['E']!.toString();
      _coord2Ctrl.text = lv['N']!.toString();
    } else {
      _coord1Ctrl.text = lat.toStringAsFixed(6);
      _coord2Ctrl.text = lng.toStringAsFixed(6);
    }
  }

  Future<void> _toggleGps() async {
    if (_gpsOn) {
      _coord1Ctrl.clear();
      _coord2Ctrl.clear();
      setState(() {
        _gpsOn = false;
        _lat = null;
        _lng = null;
      });
    } else {
      await _fetchGps();
    }
  }

  void _onCoordChanged(CoordSystem coordSystem) {
    final raw1 = _coord1Ctrl.text.trim().replaceAll("'", "");
    final raw2 = _coord2Ctrl.text.trim().replaceAll("'", "");
    final v1 = double.tryParse(raw1.replaceAll(',', '.'));
    final v2 = double.tryParse(raw2.replaceAll(',', '.'));
    if (v1 != null && v2 != null) {
      if (coordSystem == CoordSystem.lv95) {
        final wgs = lv95ToWgs(v1.round(), v2.round());
        _lat = wgs['lat'];
        _lng = wgs['lng'];
      } else {
        _lat = v1;
        _lng = v2;
      }
    } else {
      _lat = null;
      _lng = null;
    }
  }

  // ─── Tags ────────────────────────────────────────────────────────────────────

  void _addTag(List<String> path) {
    if (!_tags.any((t) => t.join('/') == path.join('/'))) {
      setState(() => _tags.add(path));
    }
  }

  void _removeTag(int idx) => setState(() => _tags.removeAt(idx));

  // ─── GBIF ────────────────────────────────────────────────────────────────────

  void _onSpeciesChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 3) {
      // Rebuild so the "add directly" row follows the text
      setState(() => _gbifSuggestions = []);
      return;
    }
    setState(() {});
    _debounce = Timer(const Duration(milliseconds: 450), () async {
      final results = await GbifService.suggest(value);
      if (mounted) setState(() => _gbifSuggestions = results);
    });
  }

  Future<void> _selectSpecies(GbifSuggestion suggestion) async {
    final path = await ref
        .read(taxonomyProvider.notifier)
        .ensurePath(suggestion.path);
    _addTag(path);
    _speciesCtrl.clear();
    setState(() => _gbifSuggestions = []);
  }

  /// Adds the typed name directly (no online lookup). The species is placed
  /// under "Incertae sedis" and can later be moved to the right branch from
  /// the Taxonomy screen.
  Future<void> _addSpeciesDirectly() async {
    final name = _speciesCtrl.text.trim();
    if (name.isEmpty) return;
    final path = await ref
        .read(taxonomyProvider.notifier)
        .ensurePath(['Incertae sedis', name]);
    _addTag(path);
    _speciesCtrl.clear();
    setState(() => _gbifSuggestions = []);
  }

  // ─── Save ────────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    await ref.read(itemsProvider.notifier).addItem(
          filePath: widget.filePath,
          type: widget.filePath != null ? ItemType.photo : ItemType.obs,
          source: StorageSource.app,
          tags: _tags,
          lat: _lat,
          lng: _lng,
        );
    if (mounted) context.go('/');
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

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
          child:
              Text('Cancel', style: jakartaStyle(13, context.appMuted)),
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
          // ── Preview + tags ────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                          ctx: context,
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

          // ── GPS / location ────────────────────────────────────────────
          _LocationSection(
            gpsOn: _gpsOn,
            coord1Ctrl: _coord1Ctrl,
            coord2Ctrl: _coord2Ctrl,
            coordSystem: settings.coordSystem,
            onToggle: _toggleGps,
            onRefetch: _fetchGps,
            onCoordChanged: () => _onCoordChanged(settings.coordSystem),
          ),
          const SizedBox(height: 16),

          // ── GBIF species search ───────────────────────────────────────
          TextField(
            controller: _speciesCtrl,
            onChanged: _onSpeciesChanged,
            decoration: InputDecoration(
              hintText: 'Search species online (GBIF)…',
              hintStyle: jakartaStyle(13, context.appMuted),
              prefixIcon: Icon(Icons.science_outlined,
                  color: context.appMuted, size: 20),
              filled: true,
              fillColor: context.appSurface2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
            ),
            style: jakartaStyle(13, context.appFg),
          ),
          if (_gbifSuggestions.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: context.appSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.appLine),
              ),
              child: Column(
                children: _gbifSuggestions
                    .map((s) => InkWell(
                          onTap: () => _selectSpecies(s),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(s.canonicalName,
                                          style: jakartaStyle(
                                              13, context.appFg,
                                              weight: FontWeight.w600)),
                                      if (s.path.length > 1)
                                        Text(
                                          s.path
                                              .take(s.path.length - 1)
                                              .toList()
                                              .reversed
                                              .join(' › '),
                                          style: jakartaStyle(
                                              11, context.appMuted),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.add,
                                    size: 16, color: context.appPrimary),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
          // Direct add — no online lookup needed
          if (_speciesCtrl.text.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            InkWell(
              onTap: _addSpeciesDirectly,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: context.appTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.playlist_add_rounded,
                        size: 18, color: context.appPrimary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Add "${_speciesCtrl.text.trim()}" directly (no search)',
                        style: jakartaStyle(13, context.appPrimary,
                            weight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // ── Browse / Find toggle ──────────────────────────────────────
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
          const SizedBox(height: 12),

          // ── Taxonomy picker ───────────────────────────────────────────
          if (_browseMode) ...[
            if (_drillParent != null)
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
            if (_drillParent != null) const SizedBox(height: 8),
            ...(_drillParent != null ? _drillParent!.children : tree)
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

  List<TaxonomyNode> _filteredNodes(
      List<TaxonomyNode> tree, String filter) {
    final flat = <TaxonomyNode>[];
    void walk(TaxonomyNode n) {
      flat.add(n);
      for (final c in n.children) {
        walk(c);
      }
    }
    for (final root in tree) {
      walk(root);
    }
    if (filter.isEmpty) return flat;
    return flat
        .where((n) => n.name.toLowerCase().contains(filter.toLowerCase()))
        .toList();
  }
}

// ─── Location section ─────────────────────────────────────────────────────────

class _LocationSection extends StatelessWidget {
  final bool gpsOn;
  final TextEditingController coord1Ctrl;
  final TextEditingController coord2Ctrl;
  final CoordSystem coordSystem;
  final Future<void> Function() onToggle;
  final Future<void> Function() onRefetch;
  final VoidCallback onCoordChanged;

  const _LocationSection({
    required this.gpsOn,
    required this.coord1Ctrl,
    required this.coord2Ctrl,
    required this.coordSystem,
    required this.onToggle,
    required this.onRefetch,
    required this.onCoordChanged,
  });

  @override
  Widget build(BuildContext context) {
    final label1 = coordSystem == CoordSystem.lv95 ? 'E' : 'Latitude';
    final label2 = coordSystem == CoordSystem.lv95 ? 'N' : 'Longitude';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: gpsOn ? context.appTint : context.appSurface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: gpsOn ? context.appPrimary : context.appLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
            child: Row(
              children: [
                Icon(Icons.location_pin,
                    size: 16,
                    color:
                        gpsOn ? context.appPrimary : context.appMuted),
                const SizedBox(width: 8),
                Text('GPS Location',
                    style: jakartaStyle(13, context.appFg,
                        weight: FontWeight.w500)),
                const Spacer(),
                if (gpsOn)
                  IconButton(
                    icon: Icon(Icons.my_location_rounded,
                        size: 18, color: context.appPrimary),
                    onPressed: onRefetch,
                    tooltip: 'Re-fetch GPS',
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                  ),
                Switch.adaptive(
                  value: gpsOn,
                  onChanged: (_) => onToggle(),
                  activeThumbColor: context.appPrimary,
                ),
              ],
            ),
          ),
          // Editable coordinate fields
          if (gpsOn)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _CoordField(
                      label: label1,
                      ctrl: coord1Ctrl,
                      onChanged: onCoordChanged,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _CoordField(
                      label: label2,
                      ctrl: coord2Ctrl,
                      onChanged: onCoordChanged,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CoordField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final VoidCallback onChanged;

  const _CoordField(
      {required this.label,
      required this.ctrl,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      onChanged: (_) => onChanged(),
      keyboardType: const TextInputType.numberWithOptions(
          decimal: true, signed: true),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: jakartaStyle(11, context.appMuted),
        filled: true,
        fillColor: context.appSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        isDense: true,
      ),
      style: jakartaStyle(12, context.appFg),
    );
  }
}

// ─── Shared sub-widgets ───────────────────────────────────────────────────────

class _TagChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  final BuildContext ctx;

  const _TagChip(
      {required this.label,
      required this.onRemove,
      required this.ctx});

  @override
  Widget build(BuildContext _) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 6, 5),
      decoration: BoxDecoration(
        color: ctx.appTint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: jakartaStyle(12, ctx.appPrimary,
                  weight: FontWeight.w600)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child:
                Icon(Icons.close, size: 14, color: ctx.appPrimary),
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
              style: jakartaStyle(13,
                  active ? context.appPrimary : context.appMuted,
                  weight: active
                      ? FontWeight.w700
                      : FontWeight.w500)),
        ),
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
              child: Icon(Icons.add, size: 16, color: context.appPrimary),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(node.name,
                style: jakartaStyle(13.5, context.appFg,
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
      {required this.node, required this.onAdd, required this.getPath});

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
              child: Icon(Icons.add, size: 16, color: context.appPrimary),
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
