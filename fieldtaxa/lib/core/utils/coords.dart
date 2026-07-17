import 'dart:math' as math;

Map<String, int> wgsToLV95(double lat, double lng) {
  final phi = (lat * 3600 - 169028.66) / 10000;
  final lam = (lng * 3600 - 26782.5) / 10000;
  final e = 2600072.37 +
      211455.93 * lam -
      10938.51 * lam * phi -
      0.36 * lam * phi * phi -
      44.54 * lam * lam * lam;
  final n = 1200147.07 +
      308807.95 * phi +
      3745.25 * lam * lam +
      76.63 * phi * phi -
      194.56 * lam * lam * phi +
      119.79 * phi * phi * phi;
  return {'E': e.round(), 'N': n.round()};
}

String formatLV95(int e, int n) {
  String fmt(int v) =>
      v.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"),
          (m) => "${m[1]}'");
  return "E ${fmt(e)}  N ${fmt(n)}";
}

String formatGps(double lat, double lng) {
  final latDir = lat >= 0 ? 'N' : 'S';
  final lngDir = lng >= 0 ? 'E' : 'W';
  return '${lat.abs().toStringAsFixed(4)}° $latDir  ${lng.abs().toStringAsFixed(4)}° $lngDir';
}

/// Swisstopo inverse approximation: LV95 (E, N) → WGS84 (lat, lng).
Map<String, double> lv95ToWgs(int e, int n) {
  final y = (e - 2600000) / 1000000.0;
  final x = (n - 1200000) / 1000000.0;
  final lambda = 2.6779094
      + 4.728982 * y
      + 0.791484 * y * x
      + 0.1306 * y * x * x
      - 0.0436 * y * y * y;
  final phi = 16.9023892
      + 3.238272 * x
      - 0.270978 * y * y
      - 0.002528 * x * x
      - 0.0447 * y * y * x
      - 0.014 * x * x * x;
  return {'lat': phi * 100 / 36, 'lng': lambda * 100 / 36};
}

({int x, int y}) latLngToTile(double lat, double lng, int zoom) {
  final t = latLngToTileXY(lat, lng, zoom);
  return (x: t.x.floor(), y: t.y.floor());
}

/// Web-Mercator projection to *fractional* tile coordinates. Multiply by the
/// tile size (256) to get world-pixel coordinates — needed to place markers
/// at their exact position on a tile grid.
({double x, double y}) latLngToTileXY(double lat, double lng, int zoom) {
  final n = math.pow(2, zoom).toDouble();
  final x = (lng + 180) / 360 * n;
  final latRad = lat * math.pi / 180;
  final y = (1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) /
      2 *
      n;
  return (x: x, y: y);
}
