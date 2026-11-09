import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'controllers/catalog_controller.dart';
import 'services/catalog_service.dart';
import 'services/translations.dart';
import 'views/catalog_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    LicenseRegistry.addLicense(() async* {
      yield LicenseEntryWithLineBreaks(['pokopiapi'], await rootBundle.loadString('assets/licenses/pokopiapi.txt'));
    });
    final preferences = await SharedPreferences.getInstance();
    final translations = await Translations.load();
    runApp(MultiProvider(providers: [
      Provider.value(value: translations),
      Provider<http.Client>(create: (_) => http.Client(), dispose: (_, client) => client.close()),
      ChangeNotifierProvider(create: (context) => CatalogController(CatalogService(context.read<http.Client>(), preferences))..refresh()),
    ], child: const PokopiaApp()));
  } catch (_) {
    runApp(MaterialApp(home: Scaffold(body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('앱을 초기화하지 못했습니다.'),
      FilledButton(onPressed: main, child: const Text('다시 시도')),
    ])))));
  }
}

class PokopiaApp extends StatelessWidget {
  const PokopiaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '포코피아 서식지 도감', debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff276952)), scaffoldBackgroundColor: const Color(0xfff5f7f1)),
    home: const CatalogView(),
  );
}
