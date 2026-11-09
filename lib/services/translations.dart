import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/pokemon.dart';

class Translations {
  Translations(this.values, [this.korean = const {}]);
  final Json korean;
  final Json values;
  static Future<Translations> load() async => Translations(
    jsonDecode(await rootBundle.loadString('assets/translations.json')) as Json,
    jsonDecode(await rootBundle.loadString('assets/visual_labels_ko.json'))
        as Json,
  );
  String translate(String section, String value) {
    final map = values[section];
    final english = map is Map ? (map[value] as String? ?? value) : value;
    final ko = korean[section];
    return ko is Map ? (ko[english] as String? ?? english) : english;
  }

  String list(String section, List<String> items) => items.isEmpty
      ? '미제공'
      : items.map((e) => translate(section, e)).join(' · ');
}
