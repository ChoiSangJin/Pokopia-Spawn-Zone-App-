import 'pokemon.dart';

class RecipeMaterial {
  RecipeMaterial.fromJson(Json json)
    : slug = text(json['slug']),
      name = text(json['name']) ?? '미제공',
      quantity = (json['quantity'] as num?)?.toDouble(),
      iconUrl = text(json['iconUrl']);
  final String name;
  final double? quantity;
  final String? iconUrl, slug;
}

class GuideItem {
  GuideItem.fromJson(Json json)
    : name = text(json['name']) ?? '미제공',
      slug = text(json['slug']) ?? '',
      description = text(json['description']),
      category = text(json['category']) ?? 'other',
      tag = text(json['tag']),
      imageUrl = text(json['imageUrl']),
      locations = strings(json['locations']),
      recipe = objects(
        json['craftingRecipe'],
      ).map(RecipeMaterial.fromJson).toList(),
      recipeStatus = text(json['recipeStatus']),
      recipeLocation = text(json['recipeLocation']),
      contentSource = text(json['contentSource']),
      availability = json['availability'] is Json
          ? json['availability'] as Json
          : {},
      eventName = json['event'] is Json
          ? text((json['event'] as Json)['name'])
          : null,
      dataStatus = text(json['dataStatus']),
      unknownFields = strings(json['unknownFields']);
  final String name, slug, category;
  final String? description,
      tag,
      imageUrl,
      recipeStatus,
      recipeLocation,
      contentSource,
      eventName,
      dataStatus;
  final List<String> locations, unknownFields;
  final List<RecipeMaterial> recipe;
  final Json availability;
}

List<GuideItem> parseItems(Object? decoded) {
  if (decoded is! List ||
      decoded.isEmpty ||
      decoded.any(
        (e) => e is! Json || text(e['slug']) == null || text(e['name']) == null,
      )) {
    throw const FormatException('아이템 데이터 형식이 올바르지 않습니다.');
  }
  final result = decoded.map((e) => GuideItem.fromJson(e as Json)).toList();
  if (result.map((e) => e.slug).toSet().length != result.length) {
    throw const FormatException('중복된 아이템입니다.');
  }
  return result;
}
