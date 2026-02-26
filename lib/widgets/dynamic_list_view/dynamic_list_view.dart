import 'package:flutter/material.dart';
import 'package:erp_dynamic_app/api/api_client.dart';
import 'package:erp_dynamic_app/models/entity_definition.dart';

import 'dynamic_list_controller.dart';
import 'dynamic_list_header.dart';
import 'dynamic_list_table.dart';

class DynamicListView extends StatefulWidget {
  final EntityDefinition entity;
  final ApiClient api;

  final Function(Map<String, dynamic>) onEdit;
  final Function() onCreate;

  const DynamicListView({
    super.key,
    required this.entity,
    required this.api,
    required this.onEdit,
    required this.onCreate,
  });

  @override
  State<DynamicListView> createState() => _DynamicListViewState();
}

class _DynamicListViewState extends State<DynamicListView> {
  late DynamicListController controller;

  @override
  void initState() {
    super.initState();
    controller = DynamicListController(this);
    controller.init();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: widget.onCreate,
        child: const Icon(Icons.add),
      ),
      appBar: DynamicListHeader(controller: controller),
      body: DynamicListTable(controller: controller, onEdit: widget.onEdit),
    );
  }
}