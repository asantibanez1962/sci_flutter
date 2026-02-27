import 'package:flutter/material.dart';
import 'api/api_client.dart';
import 'models/entity_definition.dart';
import 'screens/tab_manager/tab_manager.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ⭐ Necesario para DateFormat con locale
  await initializeDateFormatting('es_CR', null);

  runApp(const MyApp());
}


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final api = ApiClient(baseUrl: "http://localhost:5249");

  List<EntityDefinition>? entities;

  @override
  void initState() {
    super.initState();
    _loadEntities();
  }

  Future<void> _loadEntities() async {
    final result = await api.getEntities();
    setState(() {
      entities = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        locale: const Locale('es', 'CR'),
  supportedLocales: const [
    Locale('es', 'CR'),
    Locale('en', 'US'),
  ],
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],

      title: 'ERP Dinámico',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: entities == null
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            )
          : TabManager(
              api: api,
              entities: entities!,
            ),
    );
  }
}