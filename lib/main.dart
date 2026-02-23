import 'package:flutter/material.dart';
import 'api/api_client.dart';
import 'models/entity_definition.dart';
import 'screens/tab_manager/tab_manager.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ApiClient(baseUrl: "http://localhost:5249");

    return MaterialApp(
      title: 'ERP Dinámico',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: FutureBuilder<List<EntityDefinition>>(
        future: api.getEntities(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return TabManager(
            api: api,
            entities: snapshot.data!,
          );
        },
      ),
    );
  }
}