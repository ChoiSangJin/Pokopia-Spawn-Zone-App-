import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/item.dart';
import '../models/pokemon.dart';

class ItemSnapshot {
  const ItemSnapshot(
    this.items,
    this.savedAt, {
    this.cached = false,
    this.warning,
  });
  final List<GuideItem> items;
  final DateTime savedAt;
  final bool cached;
  final String? warning;
}

class ItemsService {
  ItemsService(this.client, this.preferences);
  final http.Client client;
  final SharedPreferences preferences;
  static final endpoint = Uri.parse(
    'https://raw.githubusercontent.com/QuesoCaliente/pokopiapi/main/src/data/items.json',
  );
  static const cacheKey = 'pokopia.items.v1';
  ItemSnapshot? readCache() {
    try {
      final raw = preferences.getString(cacheKey);
      if (raw == null) return null;
      final envelope = jsonDecode(raw) as Json;
      return ItemSnapshot(
        parseItems(envelope['data']),
        DateTime.parse(envelope['savedAt'] as String),
        cached: true,
      );
    } catch (_) {
      return null;
    }
  }

  Future<ItemSnapshot> fetch() async {
    final response = await client
        .get(endpoint)
        .timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) {
      throw http.ClientException('HTTP ${response.statusCode}', endpoint);
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    final items = parseItems(decoded);
    final now = DateTime.now();
    var stored = false;
    try {
      stored = await preferences.setString(
        cacheKey,
        jsonEncode({'savedAt': now.toIso8601String(), 'data': decoded}),
      );
    } catch (_) {
      stored = false;
    }
    return ItemSnapshot(
      items,
      now,
      warning: stored ? null : '아이템을 기기에 저장하지 못했습니다. 저장 공간을 확인해주세요.',
    );
  }
}
