import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokopia_spawn_zone/main.dart';
import 'package:pokopia_spawn_zone/controllers/catalog_controller.dart';
import 'package:pokopia_spawn_zone/services/catalog_service.dart';
import 'package:pokopia_spawn_zone/services/translations.dart';
import 'package:pokopia_spawn_zone/services/korean_names.dart';

void main() {
  testWidgets('cached grid searches, opens event detail and returns', (
    tester,
  ) async {
    final records =
        jsonDecode(File('test/fixtures/pokemon.json').readAsStringSync())
            as List;
    final record = records.firstWhere((e) => e['localNumber'] == 'E007');
    // Name/navigation test: keep network images out of this deterministic test.
    for (final key in [
      'types',
      'specialties',
      'climates',
      'timeAvailability',
      'habitats',
    ]) {
      for (final fact in (record[key] as List? ?? [])) {
        fact['iconUrl'] = null;
      }
    }
    SharedPreferences.setMockInitialValues({
      CatalogService.cacheKey: jsonEncode({
        'savedAt': '2026-11-09T00:00:00Z',
        'data': [record],
      }),
    });
    final prefs = await SharedPreferences.getInstance();
    final names = KoreanNames(
      MockClient((_) async => http.Response('', 503)),
      prefs,
      {350: '밀로틱'},
    );
    final state = CatalogController(
      CatalogService(MockClient((_) async => http.Response('', 503)), prefs),
      names,
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: Translations({})),
          ChangeNotifierProvider.value(value: state),
        ],
        child: const PokopiaApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('밀로틱'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'missing');
    await tester.pump();
    expect(find.textContaining('검색 결과가 없습니다'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '밀로');
    await tester.pump();
    expect(find.widgetWithText(Card, '밀로틱'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Milotic');
    await tester.pump();
    await tester.tap(find.widgetWithText(Card, '밀로틱'));
    await tester.pumpAndSettle();
    expect(find.text('#E007  밀로틱'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
    names.dispose();
  });
}
