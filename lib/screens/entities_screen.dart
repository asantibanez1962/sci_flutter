import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../models/entity_definition.dart';

class EntitiesScreen extends StatelessWidget {
  final ApiClient api;
  final List<EntityDefinition> entities;

  /// Callback que TabManager usa para abrir una nueva pestaña
  final Function(EntityDefinition) onOpenEntity;

  const EntitiesScreen({
    super.key,
    required this.api,
    required this.entities,
    required this.onOpenEntity,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Entidades")),
      body: ListView.builder(
        itemCount: entities.length,
        itemBuilder: (_, i) {
          final entity = entities[i];

          return ListTile(
            title: Text(entity.displayName),
            leading: const Icon(Icons.folder),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => onOpenEntity(entity),   // ← ahora abre pestaña
          );
        },
      ),
    );
  }
}