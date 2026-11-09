import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokopia_spawn_zone/models/item.dart';
import 'package:pokopia_spawn_zone/models/pokemon.dart';
import 'package:pokopia_spawn_zone/controllers/items_controller.dart';
import 'package:pokopia_spawn_zone/controllers/catalog_controller.dart';
import 'package:pokopia_spawn_zone/services/items_service.dart';
import 'package:pokopia_spawn_zone/services/catalog_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fixture = File('test/fixtures/items.json').readAsStringSync();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'all 1767 items parse with real Event and Basin counts and partial recipes',
    () {
      final items = parseItems(jsonDecode(fixture));
      expect(items, hasLength(1767));
      expect(items.where((i) => i.contentSource == 'event'), hasLength(46));
      expect(
        items.where((i) => i.contentSource == 'expansion-pass'),
        hasLength(219),
      );
      expect(
        items.first.imageUrl,
        'https://cdn.pokopiapi.com/images/items/honey.png',
      );
      final chest = items.firstWhere((i) => i.slug == 'big-treasure-chest');
      expect(chest.recipeStatus, 'incomplete');
      expect(chest.recipe.first.name, 'Lumber');
      expect(chest.recipe.first.quantity, 1);
      expect(chest.recipe.first.slug, 'lumber');
    },
  );
  test(
    'item fetch caches full details; filters compose and survive offline refresh',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final client = MockClient((request) async {
        expect(request.url, ItemsService.endpoint);
        return http.Response.bytes(utf8.encode(fixture), 200);
      });
      await ItemsService(client, prefs).fetch();
      final state = ItemsController(
        ItemsService(
          MockClient((_) async => throw const SocketException('offline')),
          prefs,
        ),
      );
      expect(state.snapshot!.cached, isTrue);
      expect(state.count('all'), 1767);
      state.filterSource('event');
      expect(state.visible, hasLength(46));
      state.filterSource('basin');
      expect(state.visible, hasLength(219));
      state.search('BIG TREASURE');
      expect(state.visible.single.slug, 'big-treasure-chest');
      state.filterCategory('food');
      expect(state.visible, isEmpty);
      state.filterCategory(null);
      await state.refresh();
      expect(state.error, isNotNull);
      expect(state.visible.single.recipe, isNotEmpty);
      expect(prefs.getString(CatalogService.cacheKey), isNull);
      state.dispose();
    },
  );
  test(
    'bad responses never overwrite an item cache; retry recovers first load',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await ItemsService(
        MockClient((_) async => http.Response.bytes(utf8.encode(fixture), 200)),
        prefs,
      ).fetch();
      final original = prefs.getString(ItemsService.cacheKey);
      for (final body in ['{}', '[]', '[{"name":"incomplete"}]', 'invalid']) {
        await expectLater(
          ItemsService(
            MockClient((_) async => http.Response(body, 200)),
            prefs,
          ).fetch(),
          throwsA(anything),
        );
        expect(prefs.getString(ItemsService.cacheKey), original);
      }
      await prefs.remove(ItemsService.cacheKey);
      var calls = 0;
      final state = ItemsController(
        ItemsService(
          MockClient(
            (_) async => ++calls == 1
                ? http.Response('', 503)
                : http.Response.bytes(utf8.encode(fixture), 200),
          ),
          prefs,
        ),
      );
      await state.refresh();
      expect(state.error, isNotNull);
      expect(state.snapshot, isNull);
      await state.refresh();
      expect(state.error, isNull);
      expect(state.visible, hasLength(1767));
      state.dispose();
    },
  );
  test(
    'Pokemon retains provided image URLs and filters Basin and Event entries',
    () async {
      final raw = jsonDecode(
        File('test/fixtures/pokemon.json').readAsStringSync(),
      );
      final pokemon = parseCatalog(raw);
      expect(
        pokemon.first.habitats.first.iconUrl,
        'https://cdn.pokopiapi.com/images/habitats/green-grassland.png',
      );
      expect(
        pokemon.first.specialtyFacts.first.iconUrl,
        contains('/specialties/'),
      );
      expect(pokemon.first.climateFacts.first.iconUrl, contains('/climates/'));
      final prefs = await SharedPreferences.getInstance();
      await CatalogService(
        MockClient(
          (_) async => http.Response.bytes(utf8.encode(jsonEncode(raw)), 200),
        ),
        prefs,
      ).fetch();
      final state = CatalogController(
        CatalogService(MockClient((_) async => http.Response('', 503)), prefs),
      );
      state.filterSource('basin');
      expect(state.visible, hasLength(50));
      state.filterSource('event');
      expect(state.visible, hasLength(7));
      state.dispose();
    },
  );
}
