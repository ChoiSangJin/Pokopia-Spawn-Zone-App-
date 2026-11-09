typedef Json = Map<String, dynamic>;

String? text(Object? value) => value is String && value.isNotEmpty ? value : null;
List<Json> objects(Object? value) => value is List ? value.whereType<Json>().toList() : [];
List<String> strings(Object? value) => value is List ? value.whereType<String>().toList() : [];

class Habitat {
  const Habitat({required this.name, this.rarity});
  final String name;
  final int? rarity;
  factory Habitat.fromJson(Json json) => Habitat(
    name: text(json['name']) ?? '이름 미제공',
    rarity: (json['rarity'] as num?)?.toInt(),
  );
}

class Pokemon {
  Pokemon.fromJson(Json json)
      : number = text(json['localNumber']) ?? '?',
        nationalNumber = (json['nationalNumber'] as num?)?.toInt(),
        name = text(json['name']) ?? '이름 미제공',
        slug = text(json['slug']) ?? '',
        imageUrl = text(json['imageUrl']),
        types = objects(json['types']).map((e) => text(e['name']) ?? '?').toList(),
        habitats = objects(json['habitats']).map(Habitat.fromJson).toList(),
        zones = strings(json['spawnZones']),
        climates = objects(json['climates']).map((e) => text(e['name']) ?? '?').toList(),
        times = objects(json['timeAvailability']).map((e) => text(e['name']) ?? '?').toList(),
        specialties = objects(json['specialties']).map((e) => text(e['name']) ?? '?').toList(),
        environment = text(json['idealEnvironment']),
        classification = text(json['classification']),
        height = (json['height'] as num?)?.toDouble(),
        weight = (json['weight'] as num?)?.toDouble(),
        contentSource = text(json['contentSource']),
        dataStatus = text(json['dataStatus']),
        unknownFields = strings(json['unknownFields']),
        availability = json['availability'] is Json ? json['availability'] as Json : {},
        event = json['event'] is Json ? text((json['event'] as Json)['name']) : null,
        forms = objects(json['forms']),
        produces = json['produces'] is Json ? text((json['produces'] as Json)['name']) : null;

  final String number, name, slug;
  final int? nationalNumber;
  final String? imageUrl, environment, classification, contentSource, dataStatus, event, produces;
  final List<String> types, zones, climates, times, specialties, unknownFields;
  final List<Habitat> habitats;
  final double? height, weight;
  final Json availability;
  final List<Json> forms;
  String get id => '$number-$slug';
}

List<Pokemon> parseCatalog(Object? decoded) {
  if (decoded is! List || decoded.isEmpty || decoded.any((e) => e is! Json || text(e['name']) == null || text(e['localNumber']) == null)) {
    throw const FormatException('포켓몬 데이터 형식이 올바르지 않습니다.');
  }
  final result = decoded.map((e) => Pokemon.fromJson(e as Json)).toList();
  if (result.map((e) => e.id).toSet().length != result.length) {
    throw const FormatException('중복된 도감 항목입니다.');
  }
  return result;
}
