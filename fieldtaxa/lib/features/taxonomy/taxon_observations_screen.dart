import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/models.dart';
import '../../core/providers/items_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/providers/taxonomy_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/coords.dart';
import '../../shared/widgets/map_overlay.dart';

class TaxonObservationsScreen extends ConsumerWidget {
  final String nodeId;
  const TaxonObservationsScreen({super.key, required this.nodeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taxonomy = ref.watch(taxonomyProvider.notifier);
    final path = taxonomy.pathForId(nodeId);
    final nodeName = path.isNotEmpty ? path.last : nodeId;
    final allItems = ref.watch(itemsProvider);
    final sightings = ref.watch(sightingsProvider);
    final settings = ref.watch(settingsProvider);

    // Gather all items tagged with this node (or descendants)
    final matchingNames = <String>{};
    void walkNode(TaxonomyNode n) {
      matchingNames.add(n.name);
      for (final c in n.children) walkNode(c);
    }

    final flat = ref.read(taxonomyProvider.notifier).flatList;
    final node = flat.firstWhere((n) => n.id == nodeId,
        orElse: () => TaxonomyNode(id: nodeId, name: nodeName));
    walkNode(node);

    final items = allItems
        .where((item) =>
            item.tags.any((tp) => tp.any((t) => matchingNames.contains(t))))
        .toList();

    // Stats
    final itemIds = items.map((i) => i.id).toSet();
    final itemSightings = sightings.where((s) => itemIds.contains(s.itemId)).toList();
    final withGps = itemSightings.where((s) => s.lat != null).length;
    final dates = items.map((i) => i.capturedAt).toList()..sort();
    final firstDate = dates.isNotEmpty ? _fmtDate(dates.first) : '—';
    final lastDate = dates.isNotEmpty ? _fmtDate(dates.last) : '—';

    return Scaffold(
      backgroundColor: context.appBg,
      appBar: AppBar(
        backgroundColor: context.appChrome,
        leading: GestureDetector(
          onTap: () => context.go('/taxonomy'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 8),
              Icon(Icons.arrow_back_ios_rounded,
                  size: 16, color: context.appPrimary),
              Text('Taxonomy',
                  style: jakartaStyle(14, context.appPrimary,
                      weight: FontWeight.w700)),
            ],
          ),
        ),
        leadingWidth: 100,
        title: Text(nodeName,
            style: newsreaderStyle(16, context.appFg,
                weight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.insights_rounded,
                size: 20, color: context.appPrimary),
            tooltip: 'Distribution & frequency',
            onPressed: () =>
                context.push('/taxonomy/distribution/$nodeId'),
          ),
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: context.appTint,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('${itemSightings.length}',
                style: jakartaStyle(12, context.appPrimary2,
                    weight: FontWeight.w600)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats bar
          Container(
            color: context.appSurface,
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                _StatCell(label: 'First obs.', value: firstDate),
                _Divider(),
                _StatCell(label: 'Last obs.', value: lastDate),
                _Divider(),
                _StatCell(label: 'Locations', value: '$withGps GPS'),
              ],
            ),
          ),
          // Add obs button
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
            child: OutlinedButton.icon(
              onPressed: () => _addObsOnly(context, ref),
              icon: Icon(Icons.location_pin, color: context.appPrimary, size: 18),
              label: Text('Add observation (no photo)',
                  style: jakartaStyle(13, context.appPrimary,
                      weight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: context.appPrimary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size(double.infinity, 0),
              ),
            ),
          ),
          // Items list
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text('No observations yet',
                        style: jakartaStyle(13, context.appMuted)))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
                    itemCount: items.length,
                    itemBuilder: (_, i) => _ObsRow(
                      item: items[i],
                      sightings: sightings.where((s) => s.itemId == items[i].id).toList(),
                      coordSystem: settings.coordSystem,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _addObsOnly(BuildContext context, WidgetRef ref) async {
    // Create obs-only item tagged with this node
    final taxonomy = ref.read(taxonomyProvider.notifier);
    final path = taxonomy.pathForId(nodeId);
    await ref.read(itemsProvider.notifier).addItem(
          type: ItemType.obs,
          source: StorageSource.app,
          tags: [path],
          isObsOnly: true,
        );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  const _StatCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: jakartaStyle(13, context.appFg,
                  weight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(label,
              style: jakartaStyle(10.5, context.appMuted,
                  weight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: context.appLine);
  }
}

class _ObsRow extends ConsumerWidget {
  final FieldItem item;
  final List<Sighting> sightings;
  final CoordSystem coordSystem;

  const _ObsRow({
    required this.item,
    required this.sightings,
    required this.coordSystem,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = item.lastTag;
    final dateStr = _fmtDate(item.capturedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: context.appLine),
      ),
      child: Column(
        children: [
          // Top row
          InkWell(
            onTap: () => context.push('/viewer/${item.id}'),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 58,
                      height: 58,
                      child: item.isObsOnly
                          ? Container(
                              color: context.appSurface2,
                              child: Icon(Icons.location_pin,
                                  color: context.appMuted, size: 24),
                            )
                          : (item.filePath != null &&
                                  File(item.filePath!).existsSync()
                              ? Image.file(File(item.filePath!),
                                  fit: BoxFit.cover,
                                  width: 58,
                                  height: 58)
                              : Container(color: context.appSurface2)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label,
                            style: jakartaStyle(13.5, context.appFg,
                                weight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(dateStr,
                            style: jakartaStyle(11.5, context.appMuted)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: context.appTint,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text('${sightings.length}×',
                        style: jakartaStyle(11, context.appPrimary2,
                            weight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right, color: context.appMuted, size: 18),
                  const SizedBox(width: 4),
                  // Delete item button
                  GestureDetector(
                    onTap: () => _confirmDeleteItem(context, ref),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.deleteColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Icon(Icons.delete_outline_rounded,
                          size: 15, color: AppColors.deleteColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Sighting sub-rows
          ...sightings.map((s) => _SightingSubRow(
              sighting: s, coordSystem: coordSystem)),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteItem(BuildContext context, WidgetRef ref) async {
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
    if (ok == true) {
      await ref
          .read(itemsProvider.notifier)
          .deleteItem(item.id, filePath: item.filePath);
      await ref.read(sightingsProvider.notifier).reload();
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

class _SightingSubRow extends ConsumerWidget {
  final Sighting sighting;
  final CoordSystem coordSystem;

  const _SightingSubRow(
      {required this.sighting, required this.coordSystem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateStr =
        '${_fmtDate(sighting.observedAt)} ${sighting.observedAt.hour.toString().padLeft(2, '0')}:${sighting.observedAt.minute.toString().padLeft(2, '0')}';
    String? coordStr;
    if (sighting.lat != null && sighting.lng != null) {
      if (coordSystem == CoordSystem.lv95) {
        final lv = wgsToLV95(sighting.lat!, sighting.lng!);
        coordStr = formatLV95(lv['E']!, lv['N']!);
      } else {
        coordStr = formatGps(sighting.lat!, sighting.lng!);
      }
    }

    return InkWell(
      onTap: coordStr != null && sighting.lat != null
          ? () => MapOverlaySheet.show(
              context, sighting.lat!, sighting.lng!)
          : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(72, 6, 10, 6),
        child: Row(
          children: [
            Icon(Icons.location_pin,
                size: 14, color: context.appAccent),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dateStr,
                      style: jakartaStyle(11.5, context.appMuted)),
                  if (coordStr != null)
                    Text(
                      coordStr,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: context.appFg.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            if (sighting.lat != null) ...[
              Icon(Icons.open_in_new_rounded,
                  size: 13, color: context.appMuted),
              const SizedBox(width: 8),
            ],
            // Delete sighting button
            GestureDetector(
              onTap: () => _deleteSighting(context, ref),
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppColors.deleteColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.close,
                    size: 13, color: AppColors.deleteColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteSighting(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete sighting?',
            style: newsreaderStyle(18, ctx.appFg, weight: FontWeight.w600)),
        content: Text(
          'This sighting record will be permanently removed.',
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
    if (ok == true) {
      await ref.read(sightingsProvider.notifier).deleteSighting(sighting.id);
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}
