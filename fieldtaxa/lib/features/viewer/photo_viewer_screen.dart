import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/models.dart';
import '../../core/providers/items_provider.dart';
import '../../core/providers/settings_provider.dart';
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
          // Close button
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
                    // Tag chips
                    if (item.tags.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: item.tags
                            .expand((tp) => tp)
                            .map((tag) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white
                                        .withValues(alpha: 0.15),
                                    borderRadius:
                                        BorderRadius.circular(20),
                                  ),
                                  child: Text(tag,
                                      style: jakartaStyle(
                                          12, Colors.white,
                                          weight: FontWeight.w600)),
                                ))
                            .toList(),
                      ),
                    if (coordStr != null) ...[
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => MapOverlaySheet.show(
                            context, item.lat!, item.lng!),
                        child: Row(
                          children: [
                            const Icon(Icons.location_pin,
                                color: Color(0xFFA8D87A), size: 16),
                            const SizedBox(width: 6),
                            Text(
                              coordStr,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                color: Colors.white
                                    .withValues(alpha: 0.9),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.open_in_new_rounded,
                                color:
                                    Colors.white.withValues(alpha: 0.6),
                                size: 14),
                          ],
                        ),
                      ),
                    ],
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

  Future<void> _showSightingSheet(
      BuildContext context, WidgetRef ref, FieldItem item) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SightingSheet(item: item, ref: ref),
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
