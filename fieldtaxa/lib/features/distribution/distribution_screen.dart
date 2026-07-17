import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/models.dart';
import '../../core/providers/items_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/providers/taxonomy_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/coords.dart';

const _tileSize = 256.0;

/// A group of sightings that share (approximately) the same position.
/// [count] drives the marker size, so the map shows *where* a taxon occurs
/// and *how often* it was seen there at the same time.
class _Cluster {
  final double lat;
  final double lng;
  final int count;
  const _Cluster({required this.lat, required this.lng, required this.count});
}

class DistributionScreen extends ConsumerWidget {
  final String nodeId;
  const DistributionScreen({super.key, required this.nodeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taxonomy = ref.watch(taxonomyProvider.notifier);
    final path = taxonomy.pathForId(nodeId);
    final nodeName = path.isNotEmpty ? path.last : nodeId;
    final allItems = ref.watch(itemsProvider);
    final allSightings = ref.watch(sightingsProvider);
    final settings = ref.watch(settingsProvider);

    // Every name in this node's subtree — an observation counts if any of its
    // tags mentions one of them (same rule as the Taxon Observations screen).
    final names = <String>{};
    void walk(TaxonomyNode n) {
      names.add(n.name);
      for (final c in n.children) {
        walk(c);
      }
    }

    final flat = taxonomy.flatList;
    final node = flat.firstWhere((n) => n.id == nodeId,
        orElse: () => TaxonomyNode(id: nodeId, name: nodeName));
    walk(node);

    final itemIds = allItems
        .where((i) => i.tags.any((tp) => tp.any(names.contains)))
        .map((i) => i.id)
        .toSet();
    final sightings =
        allSightings.where((s) => itemIds.contains(s.itemId)).toList();

    final located =
        sightings.where((s) => s.lat != null && s.lng != null).toList();
    final clusters = _clusterSightings(located);

    return Scaffold(
      backgroundColor: context.appBg,
      appBar: AppBar(
        backgroundColor: context.appChrome,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 8),
              Icon(Icons.arrow_back_ios_rounded,
                  size: 16, color: context.appPrimary),
              Text('Back',
                  style: jakartaStyle(14, context.appPrimary,
                      weight: FontWeight.w700)),
            ],
          ),
        ),
        leadingWidth: 88,
        title: Text('Distribution',
            style: newsreaderStyle(16, context.appFg,
                weight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 40),
        children: [
          Text(nodeName,
              style: newsreaderStyle(22, context.appFg,
                  weight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(
            '${sightings.length} sighting${sightings.length == 1 ? '' : 's'} · '
            '${located.length} georeferenced · ${clusters.length} location${clusters.length == 1 ? '' : 's'}',
            style: jakartaStyle(12, context.appMuted),
          ),
          const SizedBox(height: 16),

          // ── Geographic distribution ──────────────────────────────────
          _SectionTitle(
            title: 'Geographic distribution',
            trailing: settings.mapProvider == MapProvider.swisstopo
                ? 'Swisstopo'
                : 'System maps',
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 300,
              child: clusters.isEmpty
                  ? _EmptyMap()
                  : _DistributionMap(
                      clusters: clusters,
                      provider: settings.mapProvider,
                    ),
            ),
          ),
          if (clusters.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Circle size reflects how many sightings share a location.',
                    style: jakartaStyle(11, context.appMuted),
                  ),
                ),
                TextButton.icon(
                  onPressed: () =>
                      _openExternally(clusters, settings.mapProvider),
                  icon: Icon(Icons.open_in_new_rounded,
                      size: 15, color: context.appPrimary),
                  label: Text('Open in maps',
                      style: jakartaStyle(12, context.appPrimary,
                          weight: FontWeight.w600)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),

          // ── Observation frequency ────────────────────────────────────
          _SectionTitle(title: 'Observation frequency'),
          const SizedBox(height: 10),
          if (sightings.isEmpty)
            _EmptyNote(text: 'No sightings recorded for this taxon yet.')
          else ...[
            _ChartCard(
              label: 'By month (all years)',
              child: _BarChart(
                bars: _monthlyBars(sightings),
                highlightPeak: true,
              ),
            ),
            const SizedBox(height: 10),
            _ChartCard(
              label: 'By year',
              child: _BarChart(bars: _yearlyBars(sightings)),
            ),
          ],
        ],
      ),
    );
  }

  // ── Data shaping ───────────────────────────────────────────────────────

  /// Groups sightings whose coordinates match to ~4 decimal places (≈11 m).
  List<_Cluster> _clusterSightings(List<Sighting> located) {
    final buckets = <String, List<Sighting>>{};
    for (final s in located) {
      final key =
          '${s.lat!.toStringAsFixed(4)},${s.lng!.toStringAsFixed(4)}';
      buckets.putIfAbsent(key, () => []).add(s);
    }
    return buckets.values.map((group) {
      final lat =
          group.map((s) => s.lat!).reduce((a, b) => a + b) / group.length;
      final lng =
          group.map((s) => s.lng!).reduce((a, b) => a + b) / group.length;
      return _Cluster(lat: lat, lng: lng, count: group.length);
    }).toList();
  }

  List<_Bar> _monthlyBars(List<Sighting> sightings) {
    const labels = [
      'J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D' //
    ];
    final counts = List<int>.filled(12, 0);
    for (final s in sightings) {
      counts[s.observedAt.month - 1]++;
    }
    return List.generate(
        12, (i) => _Bar(label: labels[i], value: counts[i]));
  }

  List<_Bar> _yearlyBars(List<Sighting> sightings) {
    final counts = <int, int>{};
    for (final s in sightings) {
      counts.update(s.observedAt.year, (v) => v + 1, ifAbsent: () => 1);
    }
    final years = counts.keys.toList()..sort();
    return years
        .map((y) =>
            _Bar(label: "'${y.toString().substring(2)}", value: counts[y]!))
        .toList();
  }

  Future<void> _openExternally(
      List<_Cluster> clusters, MapProvider provider) async {
    // Centre the external map on the mean position of all sightings.
    final lat =
        clusters.map((c) => c.lat).reduce((a, b) => a + b) / clusters.length;
    final lng =
        clusters.map((c) => c.lng).reduce((a, b) => a + b) / clusters.length;
    Uri uri;
    if (provider == MapProvider.swisstopo) {
      final lv = wgsToLV95(lat, lng);
      uri = Uri.parse(
          'https://map.geo.admin.ch/?lang=en&E=${lv['E']}&N=${lv['N']}&zoom=8');
    } else {
      uri = Uri.parse('https://maps.apple.com/?ll=$lat,$lng');
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ─── Map ──────────────────────────────────────────────────────────────────────

/// A minimal slippy map that auto-fits all [clusters]. With
/// [MapProvider.swisstopo] it renders real WMTS tiles; with
/// [MapProvider.systemMaps] it draws a neutral graticule instead, keeping the
/// exact same projection so relative positions stay truthful.
class _DistributionMap extends StatelessWidget {
  final List<_Cluster> clusters;
  final MapProvider provider;

  const _DistributionMap(
      {required this.clusters, required this.provider});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      final zoom = _fitZoom(w, h);

      // World-pixel origin of the viewport (top-left corner).
      final centre = _centreTileXY(zoom);
      final originX = centre.x * _tileSize - w / 2;
      final originY = centre.y * _tileSize - h / 2;

      final maxIndex = math.pow(2, zoom).toInt() - 1;
      final firstX = (originX / _tileSize).floor();
      final lastX = ((originX + w) / _tileSize).floor();
      final firstY = (originY / _tileSize).floor();
      final lastY = ((originY + h) / _tileSize).floor();

      final tiles = <Widget>[];
      if (provider == MapProvider.swisstopo) {
        for (var x = firstX; x <= lastX; x++) {
          for (var y = firstY; y <= lastY; y++) {
            if (x < 0 || y < 0 || x > maxIndex || y > maxIndex) continue;
            tiles.add(Positioned(
              left: x * _tileSize - originX,
              top: y * _tileSize - originY,
              width: _tileSize,
              height: _tileSize,
              child: CachedNetworkImage(
                imageUrl:
                    'https://wmts.geo.admin.ch/1.0.0/ch.swisstopo.pixelkarte-farbe/default/current/3857/$zoom/$x/$y.jpeg',
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(color: context.appSurface2),
                errorWidget: (_, __, ___) =>
                    Container(color: context.appSurface2),
              ),
            ));
          }
        }
      }

      final maxCount =
          clusters.map((c) => c.count).reduce(math.max).toDouble();

      final markers = clusters.map((c) {
        final p = latLngToTileXY(c.lat, c.lng, zoom);
        final size = _markerSize(c.count, maxCount);
        return Positioned(
          left: p.x * _tileSize - originX - size / 2,
          top: p.y * _tileSize - originY - size / 2,
          width: size,
          height: size,
          child: _Marker(count: c.count, size: size),
        );
      }).toList();

      return Container(
        color: context.appSurface2,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            if (provider == MapProvider.systemMaps)
              Positioned.fill(
                child: CustomPaint(
                  painter: _GraticulePainter(
                    line: context.appLine,
                    origin: Offset(originX, originY),
                  ),
                ),
              ),
            ...tiles,
            ...markers,
          ],
        ),
      );
    });
  }

  /// Largest zoom at which the bounding box of all clusters still fits the
  /// viewport (with padding). A single point gets a mid zoom for context.
  int _fitZoom(double w, double h) {
    const pad = 56.0;
    final maxZoom = clusters.length == 1 ? 14 : 16;
    final lats = clusters.map((c) => c.lat);
    final lngs = clusters.map((c) => c.lng);
    final minLat = lats.reduce(math.min);
    final maxLat = lats.reduce(math.max);
    final minLng = lngs.reduce(math.min);
    final maxLng = lngs.reduce(math.max);

    for (var z = maxZoom; z > 1; z--) {
      final tl = latLngToTileXY(maxLat, minLng, z);
      final br = latLngToTileXY(minLat, maxLng, z);
      final wpx = (br.x - tl.x) * _tileSize;
      final hpx = (br.y - tl.y) * _tileSize;
      if (wpx <= math.max(w - pad, 1) && hpx <= math.max(h - pad, 1)) {
        return z;
      }
    }
    return 1;
  }

  ({double x, double y}) _centreTileXY(int zoom) {
    final lats = clusters.map((c) => c.lat);
    final lngs = clusters.map((c) => c.lng);
    // Average in projected space so the fit stays centred at high latitudes.
    final tl = latLngToTileXY(lats.reduce(math.max), lngs.reduce(math.min), zoom);
    final br = latLngToTileXY(lats.reduce(math.min), lngs.reduce(math.max), zoom);
    return (x: (tl.x + br.x) / 2, y: (tl.y + br.y) / 2);
  }

  double _markerSize(int count, double maxCount) {
    if (maxCount <= 1) return 22;
    // sqrt keeps the *area* proportional to the count.
    final t = math.sqrt(count / maxCount);
    return 18 + t * 20;
  }
}

class _Marker extends StatelessWidget {
  final int count;
  final double size;
  const _Marker({required this.count, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appPrimary.withValues(alpha: 0.72),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: count > 1 && size >= 22
          ? Text('$count',
              style: jakartaStyle(size >= 30 ? 12 : 10, Colors.white,
                  weight: FontWeight.w700))
          : null,
    );
  }
}

/// Neutral background grid used when the map provider is "system maps",
/// so the distribution is still readable without third-party tiles.
class _GraticulePainter extends CustomPainter {
  final Color line;
  final Offset origin;
  const _GraticulePainter({required this.line, required this.origin});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = line
      ..strokeWidth = 1;
    const step = 48.0;
    final offsetX = -(origin.dx % step);
    final offsetY = -(origin.dy % step);
    for (var x = offsetX; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = offsetY; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GraticulePainter old) =>
      old.line != line || old.origin != origin;
}

class _EmptyMap extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.appSurface2,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_off_rounded, color: context.appMuted, size: 34),
          const SizedBox(height: 8),
          Text('No georeferenced sightings',
              style: jakartaStyle(12.5, context.appMuted,
                  weight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text('Log a sighting with GPS to map this taxon',
              style: jakartaStyle(11, context.appMuted)),
        ],
      ),
    );
  }
}

// ─── Charts ───────────────────────────────────────────────────────────────────

class _Bar {
  final String label;
  final int value;
  const _Bar({required this.label, required this.value});
}

class _BarChart extends StatelessWidget {
  final List<_Bar> bars;
  final bool highlightPeak;

  const _BarChart({required this.bars, this.highlightPeak = false});

  @override
  Widget build(BuildContext context) {
    final maxV = bars.map((b) => b.value).fold(0, math.max);
    if (maxV == 0) {
      return SizedBox(
        height: 60,
        child: Center(
          child: Text('No data',
              style: jakartaStyle(12, context.appMuted)),
        ),
      );
    }

    return SizedBox(
      height: 116,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: bars.map((b) {
          final frac = b.value / maxV;
          final isPeak = highlightPeak && b.value == maxV && b.value > 0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(b.value == 0 ? '' : '${b.value}',
                      style: jakartaStyle(9.5, context.appMuted,
                          weight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  // 74 px of bar area; empty months keep a 2 px stub so the
                  // baseline stays readable.
                  Container(
                    height: math.max(2, frac * 74),
                    decoration: BoxDecoration(
                      color: b.value == 0
                          ? context.appLine
                          : (isPeak
                              ? context.appPrimary
                              : context.appPrimary.withValues(alpha: 0.45)),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3)),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(b.label,
                      style: jakartaStyle(9.5, context.appMuted,
                          weight: FontWeight.w600),
                      maxLines: 1),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String label;
  final Widget child;
  const _ChartCard({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: jakartaStyle(12, context.appMuted,
                  weight: FontWeight.w600)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

// ─── Shared bits ──────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? trailing;
  const _SectionTitle({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title,
              style: newsreaderStyle(17, context.appFg,
                  weight: FontWeight.w600)),
        ),
        if (trailing != null)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: context.appTint,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(trailing!,
                style: jakartaStyle(10.5, context.appPrimary2,
                    weight: FontWeight.w700)),
          ),
      ],
    );
  }
}

class _EmptyNote extends StatelessWidget {
  final String text;
  const _EmptyNote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appLine),
      ),
      child: Text(text,
          style: jakartaStyle(12.5, context.appMuted)),
    );
  }
}
