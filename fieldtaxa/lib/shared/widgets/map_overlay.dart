import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/models.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/coords.dart';

class MapOverlaySheet extends ConsumerWidget {
  final double lat;
  final double lng;

  const MapOverlaySheet({super.key, required this.lat, required this.lng});

  static Future<void> show(BuildContext context, double lat, double lng) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => MapOverlaySheet(lat: lat, lng: lng),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final coordSystem = settings.coordSystem;
    final mapProvider = settings.mapProvider;

    String coordStr;
    if (coordSystem == CoordSystem.lv95) {
      final lv = wgsToLV95(lat, lng);
      coordStr = formatLV95(lv['E']!, lv['N']!);
    } else {
      coordStr = formatGps(lat, lng);
    }

    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: context.appLine,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    coordStr,
                    style: jakartaStyle(13, context.appFg,
                            weight: FontWeight.w600)
                        .copyWith(fontFamily: 'monospace'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Map area
          SizedBox(
            height: 240,
            child: mapProvider == MapProvider.swisstopo
                ? _SwisstopoGrid(lat: lat, lng: lng)
                : _SystemMapsPlaceholder(),
          ),
          // Open in button
          Padding(
            padding: const EdgeInsets.all(18),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _openMap(mapProvider),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: Text('Open in …',
                    style: jakartaStyle(14, Colors.white,
                        weight: FontWeight.w700)),
                style: FilledButton.styleFrom(
                  backgroundColor: context.appPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _openMap(MapProvider provider) async {
    Uri uri;
    if (provider == MapProvider.swisstopo) {
      final lv = wgsToLV95(lat, lng);
      uri = Uri.parse(
          'https://map.geo.admin.ch/?lang=en&E=${lv['E']}&N=${lv['N']}&zoom=10');
    } else {
      // iOS: maps.apple.com, Android: geo:
      uri = Uri.parse('https://maps.apple.com/?ll=$lat,$lng');
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _SwisstopoGrid extends StatelessWidget {
  final double lat;
  final double lng;
  const _SwisstopoGrid({required this.lat, required this.lng});

  @override
  Widget build(BuildContext context) {
    const zoom = 15;
    final center = latLngToTile(lat, lng, zoom);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Stack(
        children: [
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 3,
              crossAxisSpacing: 3,
            ),
            itemCount: 9,
            itemBuilder: (_, i) {
              final row = i ~/ 3 - 1;
              final col = i % 3 - 1;
              final x = center.x + col;
              final y = center.y + row;
              final url =
                  'https://wmts.geo.admin.ch/1.0.0/ch.swisstopo.pixelkarte-farbe/default/current/3857/$zoom/$x/$y.jpeg';
              return CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: context.appSurface2),
                errorWidget: (_, __, ___) =>
                    Container(color: context.appSurface2),
              );
            },
          ),
          // Crosshair marker
          const Center(
            child: _Crosshair(),
          ),
        ],
      ),
    );
  }
}

class _Crosshair extends StatelessWidget {
  const _Crosshair();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(painter: _CrosshairPainter()),
    );
  }
}

class _CrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2D5016)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final cx = size.width / 2;
    final cy = size.height / 2;
    canvas.drawLine(Offset(cx - 8, cy), Offset(cx + 8, cy), paint);
    canvas.drawLine(Offset(cx, cy - 8), Offset(cx, cy + 8), paint);
    canvas.drawCircle(Offset(cx, cy), 3, paint..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SystemMapsPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.appSurface2,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_pin, color: context.appPrimary, size: 40),
          const SizedBox(height: 8),
          Text('Open in system maps app',
              style: jakartaStyle(12, context.appMuted,
                  weight: FontWeight.w500)),
        ],
      ),
    );
  }
}
