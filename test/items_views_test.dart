import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokopia_spawn_zone/main.dart';
import 'package:pokopia_spawn_zone/controllers/items_controller.dart';
import 'package:pokopia_spawn_zone/controllers/catalog_controller.dart';
import 'package:pokopia_spawn_zone/services/items_service.dart';
import 'package:pokopia_spawn_zone/services/catalog_service.dart';
import 'package:pokopia_spawn_zone/services/translations.dart';
import 'package:pokopia_spawn_zone/widgets/guide_visual.dart';
import 'package:pokopia_spawn_zone/models/visual_fact.dart';

void main() {
  testWidgets(
    'items tab searches, opens partial recipe, returns and preserves filters',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        ItemsService.cacheKey: jsonEncode({
          'savedAt': '2026-11-09T00:00:00Z',
          'data': [
            {
              'name': 'Coral chair',
              'slug': 'coral-chair',
              'category': 'furniture',
              'contentSource': 'expansion-pass',
              'imageUrl': null,
              'craftingRecipe': [
                {'name': 'Lumber', 'quantity': 2},
              ],
              'recipeStatus': 'incomplete',
            },
            {
              'name': 'Event gift',
              'slug': 'event-gift',
              'category': 'other',
              'contentSource': 'event',
              'imageUrl': null,
            },
          ],
        }),
      });
      final prefs = await SharedPreferences.getInstance();
      final client = MockClient((_) async => http.Response('', 503));
      final items = ItemsController(ItemsService(client, prefs));
      final pokemon = CatalogController(CatalogService(client, prefs));
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: Translations({})),
            ChangeNotifierProvider.value(value: items),
            ChangeNotifierProvider.value(value: pokemon),
          ],
          child: const PokopiaApp(),
        ),
      );
      await tester.tap(find.text('아이템'));
      await tester.pumpAndSettle();
      expect(find.text('Coral chair'), findsOneWidget);
      await tester.tap(find.text('해저 · DLC 1'));
      await tester.pumpAndSettle();
      expect(find.text('Event gift'), findsNothing);
      await tester.enterText(find.byKey(const Key('item-search')), 'CORAL');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(Card, 'Coral chair'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('일부 재료·수량이 미확인인 제작법입니다.'), 250);
      expect(find.text('일부 재료·수량이 미확인인 제작법입니다.'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('포켓몬'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('아이템'));
      await tester.pumpAndSettle();
      expect(find.text('Event gift'), findsNothing);
      expect(items.query, 'CORAL');
      await tester.pumpWidget(const SizedBox());
      items.dispose();
      pokemon.dispose();
      client.close();
    },
  );
  testWidgets(
    'visual capsules keep labels and accessible fallback without images',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisualCapsules(
              facts: const [VisualFact(name: 'Chop Wood')],
              section: 'specialties',
              translations: Translations({}, {
                'specialties': {'Chop Wood': '나무 베기'},
              }),
            ),
          ),
        ),
      );
      expect(find.text('나무 베기'), findsOneWidget);
      expect(find.byType(GuideImage), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    },
  );
}
