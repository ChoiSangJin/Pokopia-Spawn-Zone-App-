import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokopia_spawn_zone/models/pokemon.dart';
import 'package:pokopia_spawn_zone/services/catalog_service.dart';
import 'package:pokopia_spawn_zone/controllers/catalog_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fixture = File('test/fixtures/pokemon.json').readAsStringSync();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('parses all real upstream entries including null event fields', () {
    final items = parseCatalog(jsonDecode(fixture));
    expect(items, hasLength(365));
    expect(items.first.name, 'Bulbasaur');
    expect(items.first.habitats.first.name, 'Herbazal verde');
    expect(items.first.times, contains('Mañana'));
    final event = items.firstWhere((p) => p.number == 'E007');
    expect(event.imageUrl, isNull);
    expect(event.height, isNull);
    expect(event.event, 'Fetching Scales for Feebas');
    expect(event.habitats, isNotEmpty);
    expect(items.map((p) => p.id).toSet(), hasLength(items.length));
  });

  test(
    'successful fetch survives offline restart with complete details',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final online = CatalogService(
        MockClient((request) async {
          expect(request.url, CatalogService.endpoint);
          return http.Response(
            fixture,
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
        prefs,
      );
      final data = await online.fetch();
      expect(data.warning, isNull);
      final offline = CatalogController(
        CatalogService(
          MockClient((_) async => throw const SocketException('offline')),
          prefs,
        ),
      );
      expect(offline.snapshot!.cached, isTrue);
      await offline.refresh();
      expect(offline.error, isNotNull);
      expect(offline.visible, hasLength(365));
      expect(offline.visible.first.habitats.first.rarity, 1);
      offline.search('BULBASAUR');
      expect(offline.visible, hasLength(1));
      offline.search('E007');
      expect(offline.visible.single.name, 'Milotic');
      offline.filter('Planta');
      expect(offline.visible, isEmpty);
      offline.dispose();
    },
  );

  test('invalid response cannot overwrite a valid cache', () async {
    final prefs = await SharedPreferences.getInstance();
    final client = MockClient(
      (_) async => http.Response.bytes(utf8.encode(fixture), 200),
    );
    await CatalogService(client, prefs).fetch();
    final original = prefs.getString(CatalogService.cacheKey);
    for (final response in ['{}', '[]', '[{"name":"bad"}]', 'not json']) {
      final service = CatalogService(
        MockClient((_) async => http.Response(response, 200)),
        prefs,
      );
      await expectLater(service.fetch(), throwsA(anything));
      expect(prefs.getString(CatalogService.cacheKey), original);
    }
  });

  test('first-launch failure and retry recover without restarting', () async {
    var requests = 0;
    final prefs = await SharedPreferences.getInstance();
    final state = CatalogController(
      CatalogService(
        MockClient(
          (_) async => ++requests == 1
              ? http.Response('unavailable', 503)
              : http.Response.bytes(utf8.encode(fixture), 200),
        ),
        prefs,
      ),
    );
    await state.refresh();
    expect(state.error, isNotNull);
    expect(state.snapshot, isNull);
    expect(state.loading, isFalse);
    await state.refresh();
    expect(state.error, isNull);
    expect(state.visible, hasLength(365));
    state.dispose();
  });

  test('corrupt local cache is ignored', () async {
    SharedPreferences.setMockInitialValues({CatalogService.cacheKey: 'broken'});
    final prefs = await SharedPreferences.getInstance();
    expect(
      CatalogService(
        MockClient((_) async => http.Response('', 500)),
        prefs,
      ).readCache(),
      isNull,
    );
  });
}
