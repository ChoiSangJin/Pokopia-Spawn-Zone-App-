import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pokemon.dart';

/// PokeAPI species IDs are national dex numbers, never Pokopia local numbers.
class KoreanNames extends ChangeNotifier {
  KoreanNames(this.client, this.preferences, Map<int, String> seed)
    : _names = Map.of(seed) {
    try {
      final raw = preferences.getString(cacheKey);
      if (raw != null) {
        final data = jsonDecode(raw) as Json;
        for (final entry in data.entries) {
          final id = int.tryParse(entry.key);
          if (id == null || entry.value is! Json) continue;
          final value = entry.value as Json;
          final name = text(value['name']);
          final checked = DateTime.tryParse(
            value['checkedAt']?.toString() ?? '',
          );
          if (name != null && checked != null) {
            _names[id] = name;
            _checked[id] = checked;
          }
        }
      }
    } catch (_) {
      // The bundled PokeAPI names remain usable when the cache is corrupt.
    }
  }

  static const cacheKey = 'pokeapi.korean-species.v1';
  final http.Client client;
  final SharedPreferences preferences;
  final Map<int, String> _names;
  final Map<int, DateTime> _checked = {};
  final Map<int, Future<void>> _pending = {};
  bool _closed = false;

  String? nameFor(int? nationalNumber) => _names[nationalNumber];

  Future<void> refresh(int? nationalNumber) {
    if (nationalNumber == null || nationalNumber <= 0 || _closed) {
      return Future.value();
    }
    final checked = _checked[nationalNumber];
    if (checked != null &&
        DateTime.now().difference(checked) < const Duration(days: 7)) {
      return Future.value();
    }
    return _pending.putIfAbsent(
      nationalNumber,
      () => _fetch(nationalNumber).whenComplete(() {
        _pending.remove(nationalNumber);
      }),
    );
  }

  Future<void> _fetch(int number) async {
    try {
      final uri = Uri.https('pokeapi.co', '/api/v2/pokemon-species/$number/');
      final response = await client
          .get(uri)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return;
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Json;
      if (data['id'] != number) return;
      final names = objects(data['names']);
      final korean = names.where(
        (entry) =>
            entry['language'] is Map &&
            (entry['language'] as Map)['name'] == 'ko',
      );
      if (korean.isEmpty) return;
      final name = text(korean.first['name'])?.trim();
      if (name == null || name.isEmpty) return;
      _names[number] = name;
      _checked[number] = DateTime.now();
      if (!_closed) notifyListeners();
      await preferences.setString(
        cacheKey,
        jsonEncode({
          for (final entry in _checked.entries)
            '${entry.key}': {
              'name': _names[entry.key],
              'checkedAt': entry.value.toIso8601String(),
            },
        }),
      );
    } catch (_) {
      // A failed lookup never replaces an existing Korean name or blocks details.
    }
  }

  @override
  void dispose() {
    _closed = true;
    super.dispose();
  }
}
