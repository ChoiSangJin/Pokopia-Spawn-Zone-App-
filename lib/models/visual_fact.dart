import 'pokemon.dart';

class VisualFact {
  const VisualFact({required this.name, this.iconUrl});
  factory VisualFact.fromJson(Json json) => VisualFact(
    name: text(json['name']) ?? '미제공',
    iconUrl: text(json['iconUrl']),
  );
  final String name;
  final String? iconUrl;
}
