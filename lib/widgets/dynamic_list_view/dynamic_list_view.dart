import 'package:flutter/material.dart';
import 'package:erp_dynamic_app/api/api_client.dart';
import 'package:erp_dynamic_app/models/entity_definition.dart';

import 'dynamic_list_controller.dart';
import 'dynamic_list_header.dart';
import 'dynamic_list_table.dart';

class DynamicListView extends StatefulWidget {
  final EntityDefinition entity;
  final ApiClient api;
  final Map<String, dynamic>? parentFilter;
  final Function(Map<String, dynamic>) onEdit;
  final Function() onCreate;
  final List<String>? hiddenColumns;

  const DynamicListView({
    super.key,
    required this.entity,
    required this.api,
    required this.onEdit,
    required this.onCreate,
    this.parentFilter,
    this.hiddenColumns
  });

  @override
  State<DynamicListView> createState() => _DynamicListViewState();
}

class _DynamicListViewState extends State<DynamicListView> {
  late DynamicListController controller;
bool _initialized = false;

  @override
void initState() {
  super.initState();
  if (!_initialized) {
   // print(">>> DynamicListView.initState() ejecutado para entidad: ${widget.entity.name}");
  controller = DynamicListController( state: this, hiddenColumns: widget.hiddenColumns, );
  controller.init();
  _initialized = true;}

}

@override
void didUpdateWidget(covariant DynamicListView oldWidget) {
  super.didUpdateWidget(oldWidget);

  final entityChanged = oldWidget.entity.name != widget.entity.name;

  if (entityChanged) {
    controller.init();
  }
}

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //print(">>> DynamicListView.build() ejecutado para entidad: ${widget.entity.name}");
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