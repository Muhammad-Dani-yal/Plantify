class WorldPlant {
  const WorldPlant(
      {required this.key,
      required this.name,
      required this.scientific,
      required this.rank,
      required this.status,
      this.family = '',
      this.genus = '',
      this.acceptedKey});
  final int key;
  final String name, scientific, rank, status, family, genus;
  final int? acceptedKey;
  String get source => 'https://www.gbif.org/species/$key';
  factory WorldPlant.fromJson(Map<String, dynamic> json) {
    final key = json['key'];
    if (key is! int || key <= 0) {
      throw const FormatException('Invalid plant key');
    }
    String field(String name) =>
        json[name] is String ? json[name] as String : '';
    final scientific = field('scientificName');
    final name = field('canonicalName');
    if (scientific.isEmpty && name.isEmpty) {
      throw const FormatException('Missing plant name');
    }
    return WorldPlant(
        key: key,
        name: name.isEmpty ? scientific : name,
        scientific: scientific.isEmpty ? name : scientific,
        rank: field('rank'),
        status: field('taxonomicStatus'),
        family: field('family'),
        genus: field('genus'),
        acceptedKey:
            json['acceptedKey'] is int ? json['acceptedKey'] as int : null);
  }
  Map<String, dynamic> toJson() => {
        'key': key,
        'canonicalName': name,
        'scientificName': scientific,
        'rank': rank,
        'taxonomicStatus': status,
        'family': family,
        'genus': genus,
        if (acceptedKey != null) 'acceptedKey': acceptedKey
      };
}

class WorldPage {
  const WorldPage(
      {required this.items,
      required this.total,
      required this.nextOffset,
      required this.hasMore});
  final List<WorldPlant> items;
  final int total, nextOffset;
  final bool hasMore;
}
