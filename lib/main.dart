import 'package:flutter/material.dart';
import 'api/api_client.dart';
import 'models/entity_definition.dart';
import 'screens/tab_manager/tab_manager.dart';


void main() {
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