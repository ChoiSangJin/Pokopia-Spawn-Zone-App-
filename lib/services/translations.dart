import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/pokemon.dart';

class Translations {
  Translations(this.values);
  final Json values;
  static Future<Translations> load() async => Translations(
    jsonDecode(await rootBundle.loadString('assets/translations.json')) as Json,
  );
  String translate(String section, String value) {
    final map = values[section];
    return map is Map ? (map[value] as String? ?? value) : value;
  }

  String list(String section, List<String> items) => items.isEmpty
      ? '미제공'
      : items.map((e) => translate(section, e)).join(' · ');
}
