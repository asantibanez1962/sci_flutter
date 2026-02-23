import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../widgets/dynamic_list_view/dynamic_list_view.dart';
import '../models/entity_definition.dart';

class EntityDataScreen extends StatefulWidget {
  final EntityDefinition entity;
  final ApiClient api;

  final Function(EntityDefinition, Map<String, dynamic>) onEdit;
  final Function() onCreate;

  const EntityDataScreen({
    super.key,
    required this.entity,
    required this.api,
    required this.onEdit,
    required this.onCreate,
  });

  @override
  State<EntityDataScreen> createState() => _EntityDataScreenState();
}

class _EntityDataScreenState extends State<EntityDataScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DynamicListView(
        api: widget.api,
        entity: widget.entity,

        // Abrir pestaña de edición
        onEdit: (row) {
          widget.onEdit(widget.entity, row);
        },

        // Abrir pestaña de creación
        onCreate: () {
          widget.onCreate();
        },
      ),
    );
  }
}