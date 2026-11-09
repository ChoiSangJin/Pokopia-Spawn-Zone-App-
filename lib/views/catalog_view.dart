import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/catalog_controller.dart';
import '../services/translations.dart';
import '../widgets/pokemon_image.dart';
import 'detail_view.dart';

class CatalogView extends StatelessWidget {
  const CatalogView({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<CatalogController>();
    final t = context.read<Translations>();
    final visible = state.visible;
    return Scaffold(
      appBar: AppBar(title: const Text('포코피아 서식지 도감'), actions: [IconButton(tooltip: '앱 정보', onPressed: () => showAboutDialog(context: context, applicationName: '포코피아 서식지 도감', applicationVersion: '1.0.0', children: [const Text('비공식 팬 도감 · 데이터: QuesoCaliente/pokopiapi. Nintendo 및 The Pokémon Company와 관련이 없습니다.')]), icon: const Icon(Icons.info_outline)), IconButton(tooltip: '새로고침', onPressed: state.loading ? null : state.refresh, icon: const Icon(Icons.refresh))]),
      body: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), child: TextField(
          onChanged: state.search,
          decoration: InputDecoration(hintText: '포켓몬 이름 또는 도감 번호 검색', prefixIcon: const Icon(Icons.search), filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none)),
        )),
        if (state.types.isNotEmpty) SizedBox(height: 48, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), children: [
          Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: const Text('전체'), selected: state.type == null, onSelected: (_) => state.filter(null))),
          for (final type in state.types) Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(t.translate('types', type)), selected: state.type == type, onSelected: (selected) => state.filter(selected ? type : null))),
        ])),
        if (state.loading) const LinearProgressIndicator(),
        if (state.snapshot != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Row(children: [
          Expanded(child: Text('${visible.length}마리 · ${state.snapshot!.cached || state.error != null ? '저장된 도감' : '최신 도감'}', style: Theme.of(context).textTheme.labelLarge)),
          Text('${state.snapshot!.savedAt.toLocal()}'.split('.').first, style: Theme.of(context).textTheme.labelSmall),
        ])),
        if (state.error != null || state.snapshot?.warning != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
          Expanded(child: Text(state.error ?? state.snapshot!.warning!)),
          TextButton(onPressed: state.loading ? null : state.refresh, child: const Text('재시도')),
        ])),
        Expanded(child: state.snapshot == null
          ? Center(child: state.loading ? const CircularProgressIndicator() : const Text('아직 저장된 도감이 없습니다.'))
          : RefreshIndicator(onRefresh: state.refresh, child: CustomScrollView(physics: const AlwaysScrollableScrollPhysics(), slivers: [
            if (visible.isEmpty) const SliverFillRemaining(hasScrollBody: false, child: Center(child: Text('검색 결과가 없습니다. 다른 이름을 입력해주세요.')))
            else SliverPadding(padding: const EdgeInsets.all(16), sliver: SliverLayoutBuilder(builder: (context, constraints) {
              final columns = (constraints.crossAxisExtent / 180).floor().clamp(2, 6).toInt();
              return SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, mainAxisExtent: 240 + (MediaQuery.textScalerOf(context).scale(16) - 16).clamp(0, 80).toDouble(), crossAxisSpacing: 12, mainAxisSpacing: 12),
                itemCount: visible.length,
                itemBuilder: (context, index) {
                  final p = visible[index];
                  return Card(clipBehavior: Clip.antiAlias, child: InkWell(
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => DetailView(pokemon: p)));
                    },
                    child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('#${p.number}', style: Theme.of(context).textTheme.labelMedium),
                      Expanded(child: Center(child: PokemonImage(pokemon: p))),
                      Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(t.list('types', p.types), maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                    ])),
                  ));
                },
              );
            })),
          ]))),
      ]),
    );
  }
}
