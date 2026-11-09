import 'package:flutter/foundation.dart';
import '../models/pokemon.dart';
import '../services/catalog_service.dart';

class CatalogController extends ChangeNotifier {
  CatalogController(this.service) : snapshot = service.readCache();
  final CatalogService service;
  CatalogSnapshot? snapshot;
  bool loading = false;
  String? error;
  String query = '';
  String? type;

  List<Pokemon> get visible => (snapshot?.pokemon ?? <Pokemon>[]).where((p) =>
    (p.name.toLowerCase().contains(query.toLowerCase().trim()) || p.number.toLowerCase().contains(query.toLowerCase().trim())) &&
    (type == null || p.types.contains(type))).toList();
  List<String> get types => (snapshot?.pokemon.expand((p) => p.types).toSet().toList() ?? <String>[])..sort();
  void search(String value) { query = value; notifyListeners(); }
  void filter(String? value) { type = value; notifyListeners(); }
  Future<void> refresh() async {
    if (loading) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      snapshot = await service.fetch();
    } catch (_) {
      error = snapshot == null ? '데이터를 가져오지 못했습니다. 연결을 확인하고 다시 시도해주세요.' : '업데이트하지 못했습니다. 저장된 데이터를 표시합니다.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
