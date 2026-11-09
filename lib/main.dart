import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'controllers/catalog_controller.dart';
import 'services/catalog_service.dart';
import 'services/translations.dart';
import 'services/korean_names.dart';

import 'dart:convert';

import 'views/catalog_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    LicenseRegistry.addLicense(() async* {
      yield LicenseEntryWithLineBreaks([
        'PokeAPI',
      ], await rootBundle.loadString('assets/licenses/pokeapi.txt'));
      yield LicenseEntryWithLineBreaks([
        'pokopiapi',
      ], await rootBundle.loadString('assets/licenses/pokopiapi.txt'));
    });
    final preferences = await SharedPreferences.getInstance();
    final translations = await Translations.load();
    final seed =
        jsonDecode(await rootBundle.loadString('assets/korean_names.json'))
            as Map<String, dynamic>;
    final client = http.Client();
    final koreanNames = KoreanNames(
      client,
      preferences,
      seed.map((key, value) => MapEntry(int.parse(key), value as String)),
    );
    runApp(
      MultiProvider(
        providers: [
          Provider.value(value: translations),
          Provider<http.Client>(
            create: (_) => client,
            dispose: (_, client) => client.close(),
          ),
          ChangeNotifierProvider(create: (_) => koreanNames),
          ChangeNotifierProvider(
            create: (context) => CatalogController(
              CatalogService(context.read<http.Client>(), preferences),
              context.read<KoreanNames>(),
            )..refresh(),
          ),
        ],
        child: const PokopiaApp(),
      ),
    );
  } catch (_) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('앱을 초기화하지 못했습니다.'),
                FilledButton(onPressed: main, child: const Text('다시 시도')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PokopiaApp extends StatelessWidget {
  const PokopiaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '포코피아 서식지 도감',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff276952)),
      scaffoldBackgroundColor: const Color(0xfff5f7f1),
    ),
    home: const CatalogView(),
  );
}
