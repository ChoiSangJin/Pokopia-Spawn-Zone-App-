import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/items_controller.dart';
import '../models/item.dart';
import '../services/translations.dart';
import '../widgets/content_filter.dart';
import '../widgets/guide_visual.dart';
import '../widgets/guide_section.dart';

class ItemDetailView extends StatelessWidget {
  const ItemDetailView({super.key, required this.item});
  final GuideItem item;
  @override
  Widget build(BuildContext context) {
    final t = context.read<Translations>();
    return Scaffold(
      appBar: AppBar(title: Text(item.name)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: GuideImage(
                  url: item.imageUrl,
                  label: item.name,
                  size: 200,
                  fallback: Icons.inventory_2_outlined,
                ),
              ),
              Text(
                item.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Wrap(
                spacing: 8,
                children: [
                  Chip(label: Text(t.translate('categories', item.category))),
                  Chip(label: Text(contentLabel(item.contentSource))),
                  if (item.tag != null) Chip(label: Text(item.tag!)),
                ],
              ),
              GuideSection(
                title: '아이템 설명',
                children: [Text(item.description ?? '설명 미제공')],
              ),
              GuideSection(
                title: '입수 위치',
                children: [
                  if (item.locations.isEmpty) const Text('입수 위치 미제공'),
                  for (final location in item.locations)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.place_outlined),
                      title: Text(location),
                    ),
                ],
              ),
              GuideSection(
                title: '제작법',
                children: [
                  Text(switch (item.recipeStatus) {
                    'incomplete' => '일부 재료·수량이 미확인인 제작법입니다.',
                    'verified' => '확인된 제작법',
                    'none' => '제작법 미제공',
                    _ => item.recipe.isEmpty ? '제작법 미제공' : '원본 제작 재료',
                  }),
                  if (item.recipeLocation != null)
                    FieldLine('제작법 입수', item.recipeLocation!),
                  for (final material in item.recipe)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: GuideImage(
                        url:
                            material.iconUrl ??
                            context.read<ItemsController>().imageFor(
                              material.slug,
                            ),
                        label: material.name,
                        fallback: Icons.handyman_outlined,
                      ),
                      title: Text(material.name),
                      subtitle: Text(
                        '수량: ${material.quantity == null
                            ? '미제공'
                            : material.quantity! % 1 == 0
                            ? material.quantity!.toInt().toString()
                            : material.quantity.toString()}',
                      ),
                    ),
                ],
              ),
              if (item.eventName != null || item.availability.isNotEmpty)
                GuideSection(
                  title: '이벤트 · 이용 기간',
                  children: [
                    if (item.eventName != null)
                      FieldLine('이벤트', item.eventName!),
                    FieldLine(
                      '시작',
                      item.availability['startsAt']?.toString() ?? '미제공',
                    ),
                    FieldLine(
                      '종료',
                      item.availability['endsAt']?.toString() ?? '미제공',
                    ),
                    if (item.availability['timeZone'] != null)
                      FieldLine(
                        '시간 기준',
                        item.availability['timeZone'].toString(),
                      ),
                  ],
                ),
              GuideSection(
                title: '데이터 안내',
                children: [
                  FieldLine('콘텐츠', contentLabel(item.contentSource)),
                  FieldLine('확인 상태', item.dataStatus ?? '원본 값'),
                  if (item.unknownFields.isNotEmpty)
                    FieldLine('미확인 정보', item.unknownFields.join(', ')),
                  const Text(
                    '출처: QuesoCaliente/pokopiapi. 아이템 이름과 설명은 제공된 원문을 사용합니다. 이미지가 없으면 대체 아이콘을 표시합니다.',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
