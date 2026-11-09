import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokopia_spawn_zone/services/korean_names.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  final species = {
    'id': 1,
    'names': [
      {
        'language': {'name': 'en'},
        'name': 'Bulbasaur',
      },
      {
        'language': {'name': 'ko'},
        'name': '이상해씨',
      },
    ],
  };

  test(
    'uses ko language and national ID, caches across offline restart',
    () async {
      final prefs = await SharedPreferences.getInstance();
      var calls = 0;
      final client = MockClient((request) async {
        calls++;
        expect(
          request.url.toString(),
          'https://pokeapi.co/api/v2/pokemon-species/1/',
        );
        return http.Response.bytes(utf8.encode(jsonEncode(species)), 200);
      });
      final names = KoreanNames(client, prefs, {});
      await Future.wait([names.refresh(1), names.refresh(1)]);
      expect(names.nameFor(1), '이상해씨');
      expect(calls, 1);
      final restarted = KoreanNames(
        MockClient((_) async => throw const SocketException('offline')),
        prefs,
        {},
      );
      expect(restarted.nameFor(1), '이상해씨');
      await restarted.refresh(1);
      expect(restarted.nameFor(1), '이상해씨');
      names.dispose();
      restarted.dispose();
    },
  );

  test(
    'missing ko, wrong species, HTTP errors and invalid JSON preserve fallback',
    () async {
      final prefs = await SharedPreferences.getInstance();
      for (final body in [
        '{}',
        '{"id":1,"names":[]}',
        '{"id":2,"names":[{"name":"wrong","language":{"name":"ko"}}]}',
        'invalid',
      ]) {
        final names = KoreanNames(
          MockClient((_) async => http.Response(body, 200)),
          prefs,
          {1: '이상해씨'},
        );
        await names.refresh(1);
        expect(names.nameFor(1), '이상해씨');
        names.dispose();
      }
      final offline = KoreanNames(
        MockClient((_) async => http.Response('', 503)),
        prefs,
        {1: '이상해씨'},
      );
      await offline.refresh(1);
      expect(offline.nameFor(1), '이상해씨');
      expect(offline.nameFor(null), isNull);
      await offline.refresh(null);
      offline.dispose();
    },
  );

  test('bundled PokeAPI names cover the real catalog national IDs', () {
    final names =
        jsonDecode(File('assets/korean_names.json').readAsStringSync()) as Map;
    final catalog =
        jsonDecode(File('test/fixtures/pokemon.json').readAsStringSync())
            as List;
    expect(names['1'], '이상해씨');
    for (final row in catalog) {
      if (row['nationalNumber'] != null) {
        expect(names['${row['nationalNumber']}'], isNotEmpty);
      }
    }
  });
}
