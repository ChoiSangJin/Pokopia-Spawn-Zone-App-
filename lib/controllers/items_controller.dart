import 'package:flutter/foundation.dart';
import '../models/item.dart';
import '../services/items_service.dart';
import '../models/content_source.dart';

class ItemsController extends ChangeNotifier {
  ItemsController(this.service) : snapshot = service.readCache();
  final ItemsService service;
  ItemSnapshot? snapshot;
  bool loading = false;
  String? error;
  String query = '';
  String source = 'all';
  String? category;
  List<GuideItem> get visible => (snapshot?.items ?? <GuideItem>[])
      .where(
        (item) =>
            (source == 'all' || contentScope(item.contentSource) == source) &&
            (category == null || item.category == category) &&
            (item.name.toLowerCase().contains(query.toLowerCase().trim()) ||
                (item.tag ?? '').toLowerCase().contains(
                  query.toLowerCase().trim(),
                )),
      )
      .toList();
  List<String> get categories =>
      (snapshot?.items.map((e) => e.category).toSet().toList() ?? <String>[])
        ..sort();
  String? imageFor(String? slug) {
    if (slug == null) return null;
    for (final item in snapshot?.items ?? <GuideItem>[]) {
      if (item.slug == slug) return item.imageUrl;
    }
    return null;
  }

  int count(String scope) =>
      snapshot?.items
          .where(
            (e) => scope == 'all' || contentScope(e.contentSource) == scope,
          )
          .length ??
      0;
  void search(String value) {
    query = value;
    notifyListeners();
  }

  void filterSource(String value) {
    source = value;
    notifyListeners();
  }

  void filterCategory(String? value) {
    category = value;
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
          ? '아이템을 불러오지 못했습니다. 연결을 확인하고 재시도해주세요.'
          : '갱신에 실패해 저장된 아이템을 표시합니다.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
