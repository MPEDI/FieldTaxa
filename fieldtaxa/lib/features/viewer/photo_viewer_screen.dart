import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/models.dart';
import '../../core/services/gbif_service.dart';
import '../../core/providers/items_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/providers/taxonomy_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/coords.dart';
import '../../shared/widgets/map_overlay.dart';

class PhotoViewerScreen extends ConsumerWidget {
  final String itemId;
  const PhotoViewerScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itemsProvider);
    final item = items.firstWhere((i) => i.id == itemId,
        orElse: () => FieldItem(
              id: itemId,
              type: ItemType.photo,
              source: StorageSource.app,
              capturedAt: DateTime.now(),
              tags: const [],
            ));
    final sightings = ref.watch(sightingsProvider).where((s) => s.itemId == itemId).toList();
    final settings = ref.watch(settingsProvider);

    String? coordStr;
    if (item.lat != null && item.lng != null) {
      if (settings.coordSystem == CoordSystem.lv95) {
        final lv = wgsToLV95(item.lat!, item.lng!);
        coordStr = formatLV95(lv['E']!, lv['N']!);
      } else {
        coordStr = formatGps(item.lat!, item.lng!);
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xEC080B04),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Photo
          if (item.filePath != null && !item.isObsOnly)
            InteractiveViewer(
              maxScale: 6.0,
              child: Center(
                child: Image.file(
                  File(item.filePath!),
                  fit: BoxFit.contain,
                ),
              ),
            )
          else
            Center(
              child: Icon(Icons.location_pin,
                  color: AppColors.accentLight, size: 80),
            ),
          // Close button (top-right)
          Positioned(
            top: 54,
            right: 18,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
          // Delete button (top-left)
          Positioned(
            top: 54,
            left: 18,
            child: GestureDetector(
              onTap: () => _confirmDelete(context, ref, item),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: Color(0xFFFF6B6B), size: 20),
              ),
            ),
          ),
          // Bottom info area
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tags row + edit button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: item.tags.isEmpty
                              ? Text('No classification',
                                  style: jakartaStyle(
                                      12, Colors.white54))
                              : Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  // One chip per tag path, deduped, with the
                                  // species (innermost rank) first and the
                                  // higher-level ranks after it.
                                  children: {
                                    for (final tp in item.tags)
                                      tp.join('/'): tp
                                  }.values.map((tp) {
                                    final reversed =
                                        tp.reversed.toList();
                                    return Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.15),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                              text: reversed.first,
                                              style: jakartaStyle(12,
                                                  Colors.white,
                                                  weight:
                                                      FontWeight.w700),
                                            ),
                                            if (reversed.length > 1)
                                              TextSpan(
                                                text:
                                                    '  ·  ${reversed.skip(1).join(' › ')}',
                                                style: jakartaStyle(11,
                                                    Colors.white70),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () =>
                              _showReclassifySheet(context, ref, item),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                  color:
                                      Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.edit_rounded,
                                    color: Colors.white70, size: 13),
                                const SizedBox(width: 5),
                                Text('Edit',
                                    style: jakartaStyle(
                                        12, Colors.white70,
                                        weight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Coordinate row (tap = map, edit button = sheet)
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (coordStr != null)
                          Expanded(
                            child: GestureDetector(
                              onTap: () => MapOverlaySheet.show(
                                  context, item.lat!, item.lng!),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_pin,
                                      color: Color(0xFFA8D87A), size: 16),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      coordStr,
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                        color: Colors.white
                                            .withValues(alpha: 0.9),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(Icons.open_in_new_rounded,
                                      color: Colors.white
                                          .withValues(alpha: 0.6),
                                      size: 14),
                                ],
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.location_off_rounded,
                                    color:
                                        Colors.white.withValues(alpha: 0.4),
                                    size: 14),
                                const SizedBox(width: 6),
                                Text('No position',
                                    style: jakartaStyle(
                                        12,
                                        Colors.white
                                            .withValues(alpha: 0.4))),
                              ],
                            ),
                          ),
                        // Edit position button — always visible
                        GestureDetector(
                          onTap: () =>
                              _showEditPositionSheet(context, ref, item),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                  color:
                                      Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.edit_location_alt_rounded,
                                    color: Colors.white70, size: 13),
                                const SizedBox(width: 5),
                                Text('Position',
                                    style: jakartaStyle(
                                        12, Colors.white70,
                                        weight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Camera roll banner
                    if (item.source == StorageSource.roll) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA3C46C)
                              .withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.photo_library_rounded,
                                color: Color(0xFFA3C46C), size: 14),
                            const SizedBox(width: 6),
                            Text('Linked to camera roll',
                                style: jakartaStyle(
                                    11, const Color(0xFFA3C46C),
                                    weight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    // Log sighting button
                    GestureDetector(
                      onTap: () => _showSightingSheet(context, ref, item),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_pin,
                                color: Colors.white70, size: 18),
                            const SizedBox(width: 8),
                            Text('Log sighting',
                                style: jakartaStyle(
                                    13, Colors.white,
                                    weight: FontWeight.w600)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(
                                  '${sightings.length}',
                                  style: jakartaStyle(
                                      11, Colors.white,
                                      weight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, FieldItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete observation?',
            style: newsreaderStyle(18, ctx.appFg, weight: FontWeight.w600)),
        content: Text(
          'This will permanently delete the observation and all its sightings.',
          style: jakartaStyle(13, ctx.appFg),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: jakartaStyle(13, ctx.appMuted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.deleteColor),
            child: Text('Delete',
                style: jakartaStyle(13, Colors.white,
                    weight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await ref
          .read(itemsProvider.notifier)
          .deleteItem(item.id, filePath: item.filePath);
      // Reload sightings in-memory state (DB already cascade-deleted them).
      await ref.read(sightingsProvider.notifier).reload();
      if (context.mounted) context.pop();
    }
  }

  Future<void> _showSightingSheet(
      BuildContext context, WidgetRef ref, FieldItem item) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SightingSheet(item: item, ref: ref),
    );
  }

  Future<void> _showReclassifySheet(
      BuildContext context, WidgetRef ref, FieldItem item) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.97,
        builder: (ctx, scrollCtrl) =>
            _ReclassifySheet(item: item, ref: ref, scrollCtrl: scrollCtrl),
      ),
    );
  }

  Future<void> _showEditPositionSheet(
      BuildContext context, WidgetRef ref, FieldItem item) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditPositionSheet(item: item, ref: ref),
    );
  }
}

class _SightingSheet extends StatefulWidget {
  final FieldItem item;
  final WidgetRef ref;
  const _SightingSheet({required this.item, required this.ref});

  @override
  State<_SightingSheet> createState() => _SightingSheetState();
}

class _SightingSheetState extends State<_SightingSheet> {
  DateTime _at = DateTime.now();
  bool _gpsOn = false;
  double? _lat;
  double? _lng;

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
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _gpsOn = true;
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
    } catch (_) {
      setState(() {
        _gpsOn = true;
        _lat = 46.9521;
        _lng = 7.4482;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      padding: EdgeInsets.fromLTRB(
          18, 20, 18, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.appLine,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Log sighting',
              style: newsreaderStyle(20, context.appFg,
                  weight: FontWeight.w600)),
          const SizedBox(height: 16),
          // Date picker
          GestureDetector(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _at,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (d != null) {
                setState(() => _at = DateTime(
                    d.year, d.month, d.day, _at.hour, _at.minute));
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: context.appSurface2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 16, color: context.appMuted),
                  const SizedBox(width: 8),
                  Text(
                    '${_at.day.toString().padLeft(2, '0')}.${_at.month.toString().padLeft(2, '0')}.${_at.year}  ${_at.hour.toString().padLeft(2, '0')}:${_at.minute.toString().padLeft(2, '0')}',
                    style: jakartaStyle(13, context.appFg),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // GPS toggle
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _gpsOn ? context.appTint : context.appSurface2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: _gpsOn ? context.appPrimary : context.appLine),
            ),
            child: Row(
              children: [
                Icon(Icons.location_pin,
                    size: 16,
                    color: _gpsOn ? context.appPrimary : context.appMuted),
                const SizedBox(width: 8),
                Text('GPS location',
                    style: jakartaStyle(13, context.appFg,
                        weight: FontWeight.w500)),
                const Spacer(),
                Switch.adaptive(
                  value: _gpsOn,
                  onChanged: (_) => _toggleGps(),
                  activeThumbColor: context.appPrimary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                widget.ref
                    .read(sightingsProvider.notifier)
                    .addSighting(widget.item.id, _at, _lat, _lng);
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                backgroundColor: context.appPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Save sighting',
                  style: jakartaStyle(14, Colors.white,
                      weight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reclassify sheet ────────────────────────────────────────────────────────

class _ReclassifySheet extends ConsumerStatefulWidget {
  final FieldItem item;
  final WidgetRef ref;
  final ScrollController scrollCtrl;
  const _ReclassifySheet(
      {required this.item, required this.ref, required this.scrollCtrl});

  @override
  ConsumerState<_ReclassifySheet> createState() => _ReclassifySheetState();
}

class _ReclassifySheetState extends ConsumerState<_ReclassifySheet> {
  late List<List<String>> _tags;
  bool _browseMode = true;
  final _searchCtrl = TextEditingController();
  final _speciesCtrl = TextEditingController();
  TaxonomyNode? _drillParent;
  List<GbifSuggestion> _gbifSuggestions = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tags = widget.item.tags.map((tp) => List<String>.from(tp)).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _speciesCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _addTag(List<String> path) {
    if (!_tags.any((t) => t.join('/') == path.join('/'))) {
      setState(() => _tags.add(path));
    }
  }

  void _removeTag(int idx) => setState(() => _tags.removeAt(idx));

  Future<void> _save() async {
    await widget.ref
        .read(itemsProvider.notifier)
        .updateTags(widget.item.id, _tags);
    if (mounted) Navigator.pop(context);
  }

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

  @override
  Widget build(BuildContext context) {
    final tree = ref.watch(taxonomyProvider);

    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Column(
        children: [
          // ── Handle + header ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.appLine,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text('Edit classification',
                          style: newsreaderStyle(19, context.appFg,
                              weight: FontWeight.w600)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel',
                          style: jakartaStyle(13, context.appMuted)),
                    ),
                    const SizedBox(width: 4),
                    FilledButton(
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: context.appPrimary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text('Save',
                          style: jakartaStyle(13, Colors.white,
                              weight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ── Scrollable body ────────────────────────────────────────
          Expanded(
            child: ListView(
              controller: widget.scrollCtrl,
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
              children: [
                // Current tag chips
                if (_tags.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _tags.asMap().entries.map((e) {
                      final label = e.value.last;
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
                              onTap: () => _removeTag(e.key),
                              child: Icon(Icons.close,
                                  size: 14, color: context.appPrimary),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  )
                else
                  Text('No classification — add one below',
                      style: jakartaStyle(12, context.appMuted)),
                const SizedBox(height: 14),

                // GBIF species search
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
                                                style: jakartaStyle(13,
                                                    context.appFg,
                                                    weight:
                                                        FontWeight.w600)),
                                            if (s.path.length > 1)
                                              Text(
                                                s.path
                                                    .take(s.path.length - 1)
                                                    .toList()
                                                    .reversed
                                                    .join(' › '),
                                                style: jakartaStyle(
                                                    11, context.appMuted),
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                      ),
                                      Icon(Icons.add,
                                          size: 16,
                                          color: context.appPrimary),
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
                const SizedBox(height: 14),

                // Browse / Find toggle
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
                      )),
                      Expanded(
                          child: _ModeTab(
                        label: 'Find',
                        active: !_browseMode,
                        onTap: () => setState(() => _browseMode = false),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Taxonomy picker — not height-constrained; scrolls with the list
                _browseMode
                    ? _BrowsePanel(
                        tree: tree,
                        drillParent: _drillParent,
                        onAdd: _addTag,
                        onDrill: (n) => setState(() => _drillParent = n),
                        onBack: () => setState(() => _drillParent = null),
                        getPath: (id) => ref
                            .read(taxonomyProvider.notifier)
                            .pathForId(id),
                      )
                    : _FindPanel(
                        tree: tree,
                        ctrl: _searchCtrl,
                        onAdd: _addTag,
                        getPath: (id) => ref
                            .read(taxonomyProvider.notifier)
                            .pathForId(id),
                        onChanged: () => setState(() {}),
                      ),
              ],
            ),
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
  const _ModeTab({required this.label, required this.active, required this.onTap});

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
                  13,
                  active ? context.appPrimary : context.appMuted,
                  weight: active ? FontWeight.w700 : FontWeight.w500)),
        ),
      ),
    );
  }
}

class _BrowsePanel extends StatelessWidget {
  final List<TaxonomyNode> tree;
  final TaxonomyNode? drillParent;
  final ValueChanged<List<String>> onAdd;
  final ValueChanged<TaxonomyNode> onDrill;
  final VoidCallback onBack;
  final List<String> Function(String) getPath;

  const _BrowsePanel({
    required this.tree,
    required this.drillParent,
    required this.onAdd,
    required this.onDrill,
    required this.onBack,
    required this.getPath,
  });

  @override
  Widget build(BuildContext context) {
    final nodes = drillParent != null ? drillParent!.children : tree;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      children: [
        if (drillParent != null)
          GestureDetector(
            onTap: onBack,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
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
          ),
        ...nodes.map((n) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  _AddBtn(onTap: () => onAdd(getPath(n.id)), context: context),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(n.name,
                        style: jakartaStyle(13.5, context.appFg,
                            weight: FontWeight.w500)),
                  ),
                  if (n.children.isNotEmpty)
                    InkWell(
                      onTap: () => onDrill(n),
                      child: Icon(Icons.chevron_right,
                          color: context.appMuted, size: 20),
                    ),
                ],
              ),
            )),
      ],
    );
  }
}

class _FindPanel extends StatelessWidget {
  final List<TaxonomyNode> tree;
  final TextEditingController ctrl;
  final ValueChanged<List<String>> onAdd;
  final List<String> Function(String) getPath;
  final VoidCallback onChanged;

  const _FindPanel({
    required this.tree,
    required this.ctrl,
    required this.onAdd,
    required this.getPath,
    required this.onChanged,
  });

  List<TaxonomyNode> _flat() {
    final result = <TaxonomyNode>[];
    void walk(TaxonomyNode n) {
      result.add(n);
      for (final c in n.children) walk(c);
    }
    for (final r in tree) walk(r);
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final filter = ctrl.text.toLowerCase();
    final nodes = _flat()
        .where((n) => filter.isEmpty || n.name.toLowerCase().contains(filter))
        .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: TextField(
            controller: ctrl,
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              hintText: 'Search taxonomy…',
              hintStyle: jakartaStyle(13, context.appMuted),
              prefixIcon:
                  Icon(Icons.search, color: context.appMuted, size: 20),
              filled: true,
              fillColor: context.appSurface2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
            ),
            style: jakartaStyle(13, context.appFg),
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            itemCount: nodes.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  _AddBtn(
                      onTap: () => onAdd(getPath(nodes[i].id)),
                      context: context),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(nodes[i].name,
                        style: jakartaStyle(13.5, context.appFg,
                            weight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddBtn extends StatelessWidget {
  final VoidCallback onTap;
  final BuildContext context;
  const _AddBtn({required this.onTap, required this.context});

  @override
  Widget build(BuildContext _) {
    return InkWell(
      onTap: onTap,
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
    );
  }
}

// ─── Edit position sheet ──────────────────────────────────────────────────────

class _EditPositionSheet extends StatefulWidget {
  final FieldItem item;
  final WidgetRef ref;
  const _EditPositionSheet({required this.item, required this.ref});

  @override
  State<_EditPositionSheet> createState() => _EditPositionSheetState();
}

class _EditPositionSheetState extends State<_EditPositionSheet> {
  late double? _lat;
  late double? _lng;
  late final TextEditingController _coord1Ctrl;
  late final TextEditingController _coord2Ctrl;
  bool _fetching = false;

  @override
  void initState() {
    super.initState();
    _lat = widget.item.lat;
    _lng = widget.item.lng;
    _coord1Ctrl = TextEditingController();
    _coord2Ctrl = TextEditingController();
    _fillControllers();
  }

  @override
  void dispose() {
    _coord1Ctrl.dispose();
    _coord2Ctrl.dispose();
    super.dispose();
  }

  CoordSystem get _coordSystem =>
      widget.ref.read(settingsProvider).coordSystem;

  void _fillControllers() {
    if (_lat == null || _lng == null) {
      _coord1Ctrl.clear();
      _coord2Ctrl.clear();
      return;
    }
    if (_coordSystem == CoordSystem.lv95) {
      final lv = wgsToLV95(_lat!, _lng!);
      _coord1Ctrl.text = lv['E']!.toString();
      _coord2Ctrl.text = lv['N']!.toString();
    } else {
      _coord1Ctrl.text = _lat!.toStringAsFixed(6);
      _coord2Ctrl.text = _lng!.toStringAsFixed(6);
    }
  }

  void _onCoordChanged() {
    final raw1 = _coord1Ctrl.text.trim().replaceAll("'", "");
    final raw2 = _coord2Ctrl.text.trim().replaceAll("'", "");
    final v1 = double.tryParse(raw1.replaceAll(',', '.'));
    final v2 = double.tryParse(raw2.replaceAll(',', '.'));
    if (v1 != null && v2 != null) {
      if (_coordSystem == CoordSystem.lv95) {
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

  Future<void> _fetchGps() async {
    setState(() => _fetching = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        perm = await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      _lat = pos.latitude;
      _lng = pos.longitude;
      _fillControllers();
    } catch (_) {
      // GPS unavailable — leave fields as-is
    } finally {
      if (mounted) setState(() => _fetching = false);
    }
  }

  Future<void> _save() async {
    _onCoordChanged(); // ensure internal state matches fields
    await widget.ref
        .read(itemsProvider.notifier)
        .updateCoords(widget.item.id, _lat, _lng);
    if (mounted) Navigator.pop(context);
  }

  void _clearPosition() {
    _coord1Ctrl.clear();
    _coord2Ctrl.clear();
    _lat = null;
    _lng = null;
  }

  @override
  Widget build(BuildContext context) {
    final isLv95 = _coordSystem == CoordSystem.lv95;
    final label1 = isLv95 ? 'E (LV95)' : 'Latitude';
    final label2 = isLv95 ? 'N (LV95)' : 'Longitude';

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.appLine,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Header
            Row(
              children: [
                Expanded(
                  child: Text('Edit position',
                      style: newsreaderStyle(20, context.appFg,
                          weight: FontWeight.w600)),
                ),
                // Fetch GPS button
                OutlinedButton.icon(
                  onPressed: _fetching ? null : _fetchGps,
                  icon: _fetching
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: context.appPrimary),
                        )
                      : Icon(Icons.my_location_rounded,
                          size: 16, color: context.appPrimary),
                  label: Text('Fetch GPS',
                      style: jakartaStyle(12, context.appPrimary,
                          weight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: context.appPrimary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Coordinate fields
            Row(
              children: [
                Expanded(
                  child: _CoordInput(
                    label: label1,
                    ctrl: _coord1Ctrl,
                    onChanged: _onCoordChanged,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CoordInput(
                    label: label2,
                    ctrl: _coord2Ctrl,
                    onChanged: _onCoordChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Clear link
            GestureDetector(
              onTap: () => setState(_clearPosition),
              child: Text('Clear position',
                  style: jakartaStyle(12, context.appMuted)
                      .copyWith(decoration: TextDecoration.underline)),
            ),
            const SizedBox(height: 20),
            // Save button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: context.appPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Save position',
                    style: jakartaStyle(14, Colors.white,
                        weight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoordInput extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final VoidCallback onChanged;

  const _CoordInput(
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
        fillColor: context.appSurface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      style: jakartaStyle(13, context.appFg),
    );
  }
}
