//import 'dart:convert';
import 'package:flutter/material.dart';

//import '../../api/api_client.dart';
import '../../api/column_visibility_api.dart';
import '../../filters/column_filter.dart';
//import '../../models/filter_condition.dart';
import '../../models/column_definition.dart';

import 'utils/infer_type.dart';
import '../../widgets/column_visibility_dialog.dart';

class DynamicListController {
  final dynamic state;

  DynamicListController(this.state);

  List<Map<String, dynamic>> rows = [];
  List<ColumnDefinition> columns = [];
  Map<String, ColumnFilter> columnFilters = {};

  String? sortColumn;
  bool sortAscending = true;
  bool tableVisible = true;

  late ColumnVisibilityApi columnApi;

  Future<void> init() async {
    columnApi = ColumnVisibilityApi(baseUrl: state.widget.api.baseUrl);
    await _loadData();
    await _loadColumnVisibility();
    state.setState(() {});
  }

  Future<void> _loadData() async {
    try {
      final filtersJson =
          columnFilters.values.map((f) => f.toJson()).toList();

      /*final data = await state.widget.api.getList(
        state.widget.entity.name,
        filters: filtersJson.isEmpty ? null : filtersJson,
      );*/

    final List<Map<String, dynamic>> data =
      List<Map<String, dynamic>>.from(
      await state.widget.api.getList(
        state.widget.entity.name,
        filters: filtersJson.isEmpty ? null : filtersJson,
      ),
    );
      if (data.isNotEmpty) {
        rows = data.map((row) {
          return row.map((key, value) {
            final normalizedKey = key.toString().trim();
            final fixedKey =
                normalizedKey[0].toUpperCase() + normalizedKey.substring(1);
            return MapEntry(fixedKey, value);
          });
        }).toList();

        columns = rows.first.keys.map((c) {
          final field = c.toString().trim();
          final label = field[0].toUpperCase() + field.substring(1);

          return ColumnDefinition(
            field: field,
            label: label,
            visible: true,
          );
        }).toList();

        await _loadColumnVisibility();
        state.setState(() {});
      } else {
        state.setState(() => columns = []);
      }
    } catch (e) {
      debugPrint("❌ Error cargando datos: $e");
    }
  }

  Future<void> _loadColumnVisibility() async {
    final prefs =
        await columnApi.getColumnVisibility(state.widget.entity.name);

    if (prefs.isEmpty) return;

    final prefsMap = {for (var p in prefs) p["field"]: p["visible"]};

    for (var col in columns) {
      if (prefsMap.containsKey(col.field)) {
        col.visible = prefsMap[col.field] as bool;
      }
    }
  }

  void applyFilter(ColumnFilter filter) {
    columnFilters[filter.field] = filter;
    _loadData();
  }

  void clearFilter(String field) {
    columnFilters.remove(field);
    _loadData();
  }

  void clearAllFilters() {
    columnFilters.clear();
    _loadData();
  }

  void sortByColumn(String column, {bool? ascending}) {
    if (ascending != null) {
      sortAscending = ascending;
      sortColumn = column;
    } else if (sortColumn == column) {
      sortAscending = !sortAscending;
    } else {
      sortColumn = column;
      sortAscending = true;
    }

    rows.sort((a, b) {
      final v1 = a[column];
      final v2 = b[column];

      if (v1 is Comparable && v2 is Comparable) {
        return sortAscending ? v1.compareTo(v2) : v2.compareTo(v1);
      }
      return 0;
    });

    state.setState(() {});
  }

  Future<String?> promptValue(String title, String column) async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: state.context,
      builder: (_) {
        return AlertDialog(
          title: Text("$title ($column)"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: "Valor"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(state.context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(state.context, controller.text),
              child: const Text("Aceptar"),
            ),
          ],
        );
      },
    );
  }

  Future<void> openColumnVisibilityDialog() async {
    final result = await showDialog(
      context: state.context,
      builder: (_) => ColumnVisibilityDialog(columns: columns),
    );

    if (result == true) {
      state.setState(() => tableVisible = false);
      await Future.delayed(const Duration(milliseconds: 150));

      final payload = columns
          .map((c) => {"field": c.field, "visible": c.visible})
          .toList();

      await columnApi.saveColumnVisibility(
          state.widget.entity.name, payload);

      await _loadColumnVisibility();

      state.setState(() => tableVisible = true);
    }
  }

  String inferType(String field) => inferTypeFromRows(field, rows);
}