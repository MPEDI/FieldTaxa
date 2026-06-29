import 'dart:convert';
import 'package:http/http.dart' as http;

class GbifSuggestion {
  final String canonicalName;
  final List<String> path;

  const GbifSuggestion({required this.canonicalName, required this.path});
}

class GbifService {
  static Future<List<GbifSuggestion>> suggest(String query) async {
    if (query.trim().length < 3) return [];
    final uri = Uri.https(
      'api.gbif.org',
      '/v1/species/suggest',
      {'q': query.trim(), 'limit': '8'},
    );
    try {
      final resp =
          await http.get(uri).timeout(const Duration(seconds: 6));
      if (resp.statusCode != 200) return [];
      final list = jsonDecode(resp.body) as List;
      return list
          .map((item) {
            final name = (item['canonicalName'] as String?) ??
                (item['scientificName'] as String?) ??
                '';
            if (name.isEmpty) return null;
            final path = <String>[];
            for (final rank in [
              'kingdom',
              'phylum',
              'class',
              'order',
              'family',
              'genus',
            ]) {
              final v = item[rank] as String?;
              if (v != null && v.isNotEmpty) path.add(v);
            }
            // Add the canonical name as the leaf only if it's not already the genus
            if (path.isEmpty || path.last.toLowerCase() != name.toLowerCase()) {
              path.add(name);
            }
            return GbifSuggestion(canonicalName: name, path: path);
          })
          .whereType<GbifSuggestion>()
          .toList();
    } catch (_) {
      return [];
    }
  }
}
