import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import '../../api/column_visibility_api.dart';
import '../../filters/column_filter.dart';
import '../../models/field_definition.dart';
import '../../models/column_definition.dart';
import '../../services/lookup_cache.dart';
import 'utils/infer_type.dart';
import '../../widgets/column_visibility_dialog.dart';

class DynamicListController {
  final dynamic state;


  DynamicListController(this.state);

  bool _disposed = false;

  void dispose() {
    _disposed = true;
  }

  bool get isDisposed => _disposed;

  List<Map<String, dynamic>> rows = [];
  List<ColumnDefinition> columns = [];
  Map<String, ColumnFilter> columnFilters = {};
  List<FieldDefinition> metadataFields = [];
  Map<String, Map<int, String>> lookupMaps = {};

  String? sortColumn;
  bool sortAscending = true;
  bool tableVisible = true;
  String? hoveredHeader;
  int? hoveredRow;
  
  late ColumnVisibilityApi columnApi;

  Future<void> init() async {
    columnApi = ColumnVisibilityApi(baseUrl: state.widget.api.baseUrl);
    await _loadData();
    await _loadColumnVisibility();
    if (!isDisposed && state.mounted) {
      state.setState(() {});
    }
  }

  Future<void> _loadData() async {
    try {
      final filtersJson =
          columnFilters.values.map((f) => f.toJson()).toList();

      // 1) Cargar metadata primero
      final rawColumns =
          await state.widget.api.getColumns(state.widget.entity.name);

      metadataFields = rawColumns
          .map<FieldDefinition>((e) => FieldDefinition.fromJson(e))
          .toList();
  
      debugPrint("Metadata types: ${metadataFields.map((f) => "${f.name}=${f.dataType}").toList()}");

      // 2) Cargar datos
      final List<Map<String, dynamic>> data =
          List<Map<String, dynamic>>.from(
        await state.widget.api.getList(
          state.widget.entity.name,
          filters: filtersJson.isEmpty ? null : filtersJson,
        ),
      );

      rows = data;
      debugPrint("ROW RAW: ${data.first}");

      // 3) Construir columnas desde metadata (NO desde rows)
      columns = metadataFields.map((f) {
        return ColumnDefinition(
          field: f.name,
          label: f.label,
          visible: true,
        );
      }).toList();

     
      
      // 4) Cargar lookups
      await loadLookups();

      // 5) Aplicar visibilidad guardada
      await _loadColumnVisibility();

      if (!isDisposed && state.mounted) {
        state.setState(() {});
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
      /*
      if (prefsMap.containsKey(col.field)) {
        col.visible = prefsMap[col.field] as bool;
      }*/
      final v = prefsMap[col.field];
      if (v is bool) {
        col.visible = v;
      }
          }
  }

/*
  void applyFilter(ColumnFilter filter) {
    print("Filtrando por campo: ${filter.field}");
    print("Campos reales de la fila: ${rows.first.keys}");
    columnFilters[filter.field] = filter;
    _loadData();
  }
*/
Future<void> applyFilter(ColumnFilter filter) async {
  print("Filtrando por campo: ${filter.field}");
  print("Campos reales de la fila: ${rows.first.keys}");

  columnFilters[filter.field] = filter;

  final filtersJson = columnFilters.values.map((f) => f.toJson()).toList();

  rows = await state.widget.api.getList(
    state.widget.entity.name,
    filters: filtersJson.isEmpty ? null : filtersJson,
  );

  if (!isDisposed && state.mounted) {
    state.setState(() {});
  }
}

  void clearFilter(String field) {
    columnFilters.remove(field);
    _loadData();
  }

  void clearAllFilters() {
    columnFilters.clear();
    _loadData();
  }

  Future<void> loadLookups() async {
    for (var f in metadataFields) {
      if (f.dataType == "lookup" && f.lookupEntity != null) {
        final entity = f.lookupEntity!;

        if (LookupCache.has(entity)) {
          lookupMaps[f.name] = LookupCache.get(entity)!;
          continue;
        }

        final url =
            Uri.parse("${state.widget.api.baseUrl}/lookup/$entity");
        final res = await http.get(url);

        if (res.statusCode != 200 || res.body.isEmpty) {
          lookupMaps[f.name] = {};
          continue;
        }

        final list = jsonDecode(res.body) as List;

        final map = {
          for (var item in list)
            item["id"] as int: item["label"] as String
        };

        LookupCache.set(entity, map);
        lookupMaps[f.name] = map;
      }
    }
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

    if (!isDisposed && state.mounted) {
      state.setState(() {});
    }
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
      if (!isDisposed && state.mounted) {
        state.setState(() => tableVisible = false);
      }

      await Future.delayed(const Duration(milliseconds: 150));

      final payload = columns
          .map((c) => {"field": c.field, "visible": c.visible})
          .toList();

      await columnApi.saveColumnVisibility(
          state.widget.entity.name, payload);

      await _loadColumnVisibility();

      if (!isDisposed && state.mounted) {
        state.setState(() => tableVisible = true);
      }
    }
  }

  String inferType(String field) => inferTypeFromRows(field, rows);
}