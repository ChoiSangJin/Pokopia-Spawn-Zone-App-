import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pokemon.dart';
import '../controllers/catalog_controller.dart';
import '../services/translations.dart';
import '../widgets/pokemon_image.dart';
import '../widgets/guide_visual.dart';
import '../widgets/content_filter.dart';

class DetailView extends StatefulWidget {
  const DetailView({super.key, required this.pokemon});
  final Pokemon pokemon;
  @override
  State<DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<DetailView> {
  @override
  void initState() {
    super.initState();
    context.read<CatalogController>().refreshName(widget.pokemon);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pokemon;
    final displayName = context.watch<CatalogController>().displayName(p);
    final t = context.read<Translations>();
    return Scaffold(
      appBar: AppBar(title: Text(displayName)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SizedBox(height: 260, child: PokemonImage(pokemon: p)),
              Text(
                '#${p.number}  $displayName',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              if (displayName != p.name) Text(p.name),
              const SizedBox(height: 8),
              VisualCapsules(
                facts: p.typeFacts,
                section: 'types',
                translations: t,
              ),
              Chip(label: Text(contentLabel(p.contentSource))),
              _section(context, '기본 프로필', [
                _row('전국 도감', p.nationalNumber?.toString() ?? '미제공'),
                _row(
                  '키 / 무게',
                  '${p.height == null ? '미제공' : '${p.height} m'} / ${p.weight == null ? '미제공' : '${p.weight} kg'}',
                ),
                _row(
                  '분류',
                  p.classification == null
                      ? '미제공'
                      : t.translate('classifications', p.classification!),
                ),
                const Text('특기', style: TextStyle(fontWeight: FontWeight.w600)),
                VisualCapsules(
                  facts: p.specialtyFacts,
                  section: 'specialties',
                  translations: t,
                  fallback: Icons.handyman_outlined,
                ),
                if (p.produceFact != null)
                  VisualCapsules(
                    facts: [p.produceFact!],
                    section: 'produces',
                    translations: t,
                    fallback: Icons.eco_outlined,
                  ),
              ]),
              _section(context, '서식 조건', [
                _row('출현 지역', t.list('spawnZones', p.zones)),
                _row(
                  '선호 환경',
                  p.environment == null
                      ? '미제공'
                      : t.translate('idealEnvironments', p.environment!),
                ),
                const Text('날씨', style: TextStyle(fontWeight: FontWeight.w600)),
                VisualCapsules(
                  facts: p.climateFacts,
                  section: 'climates',
                  translations: t,
                  fallback: Icons.wb_sunny_outlined,
                ),
                const Text(
                  '시간대',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                VisualCapsules(
                  facts: p.timeFacts,
                  section: 'time',
                  translations: t,
                  fallback: Icons.schedule,
                ),
              ]),
              Text('서식지', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              if (p.habitats.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('서식지 정보가 아직 제공되지 않았습니다.'),
                  ),
                ),
              for (final habitat in p.habitats)
                Card(
                  child: ListTile(
                    leading: GuideImage(
                      url: habitat.iconUrl,
                      label: habitat.name,
                      size: 60,
                      fallback: Icons.forest_outlined,
                    ),
                    title: Text(t.translate('habitats', habitat.name)),
                    subtitle: Text(
                      '희귀도: ${habitat.rarity?.toString() ?? '미제공'}',
                    ),
                  ),
                ),
              if (p.availability.isNotEmpty || p.event != null)
                _section(context, '이벤트 및 이용 조건', [
                  if (p.event != null) _row('이벤트', p.event!),
                  for (final entry in p.availability.entries)
                    _row(entry.key, entry.value?.toString() ?? '미제공'),
                ]),
              if (p.forms.isNotEmpty)
                _section(context, '폼', [
                  for (final form in p.forms)
                    _row(
                      text(form['name']) ?? text(form['slug']) ?? '폼',
                      form.entries
                          .where((e) => e.key != 'imageUrl' && e.key != 'name')
                          .map((e) => '${e.key}: ${e.value ?? '미제공'}')
                          .join('\n'),
                    ),
                ]),
              _section(context, '데이터 안내', [
                _row('콘텐츠', contentLabel(p.contentSource)),
                _row('확인 상태', p.dataStatus ?? '원본 값'),
                if (p.unknownFields.isNotEmpty)
                  _row('미확인 필드', p.unknownFields.join(', ')),
                const Text(
                  '출처: QuesoCaliente/pokopiapi. 포켓몬 이름은 PokeAPI 한국어 명칭을 사용하며 미제공 시 원문을 표시합니다. 서식 조건은 제공되는 영어 번역 또는 원문으로 표시합니다. 스탯과 출현 방식 등 원본에 없는 정보는 추정하지 않습니다. 이미지도 원본 해상도를 사용합니다.',
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(value),
      ],
    ),
  );
  Widget _section(BuildContext context, String title, List<Widget> children) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                ),
              ),
            ),
          ],
        ),
      );
}
