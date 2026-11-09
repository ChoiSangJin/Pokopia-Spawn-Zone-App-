import 'package:flutter/foundation.dart';

import '../models/pokemon.dart';
import '../services/catalog_service.dart';
import '../services/korean_names.dart';
import '../models/content_source.dart';

class CatalogController extends ChangeNotifier {
  CatalogController(this.service, [this.names])
    : snapshot = service.readCache() {
    names?.addListener(notifyListeners);
  }
  final KoreanNames? names;
  String displayName(Pokemon pokemon) =>
      names?.nameFor(pokemon.nationalNumber) ?? pokemon.name;
  Future<void> refreshName(Pokemon pokemon) async =>
      names?.refresh(pokemon.nationalNumber);
  @override
  void dispose() {
    names?.removeListener(notifyListeners);
    super.dispose();
  }

  final CatalogService service;
  CatalogSnapshot? snapshot;
  bool loading = false;
  String? error;
  String query = '';
  String? type;
  String source = 'all';
  int countSource(String scope) =>
      snapshot?.pokemon
          .where(
            (p) => scope == 'all' || contentScope(p.contentSource) == scope,
          )
          .length ??
      0;
  void filterSource(String value) {
    source = value;
    notifyListeners();
  }

  List<Pokemon> get visible => (snapshot?.pokemon ?? <Pokemon>[])
      .where(
        (p) =>
            (displayName(
                  p,
                ).toLowerCase().contains(query.toLowerCase().trim()) ||
                p.name.toLowerCase().contains(query.toLowerCase().trim()) ||
                p.number.toLowerCase().contains(query.toLowerCase().trim())) &&
            (type == null || p.types.contains(type)) &&
            (source == 'all' || contentScope(p.contentSource) == source),
      )
      .toList();
  List<String> get types =>
      (snapshot?.pokemon.expand((p) => p.types).toSet().toList() ?? <String>[])
        ..sort();
  void search(String value) {
    query = value;
    notifyListeners();
  }

  void filter(String? value) {
    type = value;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (loading) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      snapshot = await service.fetch();
    } catch (_) {
      error = snapshot == null
          ? '데이터를 가져오지 못했습니다. 연결을 확인하고 다시 시도해주세요.'
          : '업데이트하지 못했습니다. 저장된 데이터를 표시합니다.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
