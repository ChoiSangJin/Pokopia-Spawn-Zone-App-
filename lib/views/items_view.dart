import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/items_controller.dart';
import '../services/translations.dart';
import '../widgets/content_filter.dart';
import '../widgets/guide_visual.dart';
import 'item_detail_view.dart';

class ItemsView extends StatelessWidget {
  const ItemsView({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<ItemsController>();
    final t = context.read<Translations>();
    final items = state.visible;
    return Scaffold(
      appBar: AppBar(
        title: const Text('아이템 도감'),
        actions: [
          IconButton(
            tooltip: '아이템 새로고침',
            onPressed: state.loading ? null : state.refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              key: const Key('item-search'),
              onChanged: state.search,
              decoration: const InputDecoration(
                labelText: '아이템 이름 · 태그 검색',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          ContentFilter(
            selected: state.source,
            onChanged: state.filterSource,
            count: state.count,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${items.length}개 · ${state.snapshot?.cached == true || state.error != null ? '저장된 아이템' : '아이템 도감'}',
                  ),
                ),
                DropdownButton<String>(
                  value: state.category ?? 'all',
                  hint: const Text('분류'),
                  onChanged: (value) =>
                      state.filterCategory(value == 'all' ? null : value),
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('모든 분류')),
                    for (final category in state.categories)
                      DropdownMenuItem(
                        value: category,
                        child: Text(t.translate('categories', category)),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (state.source == 'basin')
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Bubbly Basin 해저 확장팩 · 일부 이미지와 제작법은 미제공 상태입니다.'),
            ),
          if (state.source == 'event')
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('과거 이벤트도 포함합니다. 상세 화면에서 기간을 확인하세요.'),
            ),
          if (state.loading) const LinearProgressIndicator(),
          if (state.error != null || state.snapshot?.warning != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(state.error ?? state.snapshot!.warning!),
                  ),
                  TextButton(
                    onPressed: state.loading ? null : state.refresh,
                    child: const Text('재시도'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: state.snapshot == null
                ? Center(
                    child: state.loading
                        ? const CircularProgressIndicator()
                        : const Text('아직 저장된 아이템이 없습니다.'),
                  )
                : RefreshIndicator(
                    onRefresh: state.refresh,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        if (items.isEmpty)
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(child: Text('조건에 맞는 아이템이 없습니다.')),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.all(16),
                            sliver: SliverLayoutBuilder(
                              builder: (context, constraints) =>
                                  SliverGrid.builder(
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount:
                                              (constraints.crossAxisExtent /
                                                      180)
                                                  .floor()
                                                  .clamp(2, 6)
                                                  .toInt(),
                                          mainAxisExtent:
                                              235 +
                                              (MediaQuery.textScalerOf(
                                                        context,
                                                      ).scale(16) -
                                                      16)
                                                  .clamp(0, 100),
                                          mainAxisSpacing: 12,
                                          crossAxisSpacing: 12,
                                        ),
                                    itemCount: items.length,
                                    itemBuilder: (context, index) {
                                      final item = items[index];
                                      return Card(
                                        clipBehavior: Clip.antiAlias,
                                        child: InkWell(
                                          onTap: () {
                                            FocusScope.of(context).unfocus();
                                            Navigator.of(context).push(
                                              MaterialPageRoute<void>(
                                                builder: (_) =>
                                                    ItemDetailView(item: item),
                                              ),
                                            );
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: Center(
                                                    child: GuideImage(
                                                      url: item.imageUrl,
                                                      label: item.name,
                                                      size: 88,
                                                      fallback: Icons
                                                          .inventory_2_outlined,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  item.name,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.titleMedium,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  t.translate(
                                                    'categories',
                                                    item.category,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  contentLabel(
                                                    item.contentSource,
                                                  ),
                                                  style: TextStyle(
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
