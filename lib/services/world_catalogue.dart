import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/world_plant.dart';

class WorldCatalogue {
  WorldCatalogue({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  static const backbone = 'd7dddbf4-2cf0-4f39-9b2a-bb099caae36c';
  static const pageSize = 24;
  Future<WorldPage> search(
      {String query = '',
      String rank = 'SPECIES',
      bool acceptedOnly = true,
      int offset = 0,
      int limit = pageSize}) async {
    final uri = Uri.https('api.gbif.org', '/v1/species/search', {
      'highertaxon_key': '6',
      'datasetKey': backbone,
      'limit': '$limit',
      'offset': '$offset',
      if (query.trim().isNotEmpty) 'q': query.trim(),
      if (rank.isNotEmpty) 'rank': rank,
      if (acceptedOnly) 'status': 'ACCEPTED',
    });
    final response =
        await _client.get(uri).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw StateError(
          'The world catalogue is temporarily unavailable. Please retry.');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final raw = data['results'] as List? ?? [];
    final items = <WorldPlant>[];
    for (final value in raw) {
      if (value is! Map<String, dynamic>) continue;
      try {
        items.add(WorldPlant.fromJson(value));
      } on FormatException {
        continue;
      }
    }
    final next = offset + raw.length;
    return WorldPage(
        items: items,
        total: (data['count'] as num?)?.toInt() ?? items.length,
        nextOffset: next,
        hasMore:
            raw.isNotEmpty && data['endOfRecords'] != true && next < 10000);
  }

  void close() => _client.close();
}
