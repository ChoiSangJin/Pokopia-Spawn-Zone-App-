import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pokemon.dart';

class CatalogSnapshot {
  const CatalogSnapshot(this.pokemon, this.savedAt, {this.cached = false, this.warning});
  final List<Pokemon> pokemon;
  final DateTime savedAt;
  final bool cached;
  final String? warning;
}

class CatalogService {
  CatalogService(this.client, this.preferences);
  final http.Client client;
  final SharedPreferences preferences;
  static final endpoint = Uri.parse('https://raw.githubusercontent.com/QuesoCaliente/pokopiapi/main/src/data/pokemon.json');
  static const cacheKey = 'pokopia.catalog.v1';

  CatalogSnapshot? readCache() {
    try {
      final raw = preferences.getString(cacheKey);
      if (raw == null) return null;
      final envelope = jsonDecode(raw) as Json;
      return CatalogSnapshot(parseCatalog(envelope['data']), DateTime.parse(envelope['savedAt'] as String), cached: true);
    } catch (_) {
      return null;
    }
  }

  Future<CatalogSnapshot> fetch() async {
    final response = await client.get(endpoint).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw http.ClientException('HTTP ${response.statusCode}', endpoint);
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    final pokemon = parseCatalog(decoded);
    final now = DateTime.now();
    var stored = false;
    try {
      stored = await preferences.setString(cacheKey, jsonEncode({'savedAt': now.toIso8601String(), 'data': decoded}));
    } catch (_) {
      stored = false;
    }
    return CatalogSnapshot(pokemon, now, warning: stored ? null : '기기 저장 공간을 확인해주세요. 이번 데이터는 오프라인으로 저장되지 않았습니다.');
  }
}
