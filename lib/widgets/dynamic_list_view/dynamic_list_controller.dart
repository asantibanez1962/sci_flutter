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
    print("Cargando datos de entidad: ${state.widget.entity.name}");
print("Filtros aplicados: ${state.widget.parentFilter}");

    // 1) Filtros de columnas
    final columnFiltersJson =
        columnFilters.values.map((f) => f.toJson()).toList();

print("Filtros de columnas: $columnFiltersJson");
    // 2) Filtros de relación (parentFilter)
    final List<Map<String, dynamic>> relationFilters = [];
    if (state.widget.parentFilter != null) {
      state.widget.parentFilter!.forEach((field, value) {
        relationFilters.add({
          "field": field,
          "logic": value["logic"] ,
          "conditions":value["conditions"],
        });
      });
    }

/* era
relationFilters.add({
  "field": field,
  "operator": "equals",
  "value": value,
});
*/

    final allFilters = [
      ...relationFilters,
      ...columnFiltersJson,
    ];

print("all filter: $allFilters");

    // 3) Metadata
    final rawColumns =
        await state.widget.api.getColumns(state.widget.entity.name);

print("2");
    metadataFields = rawColumns
        .map<FieldDefinition>((e) => FieldDefinition.fromJson(e))
        .toList();
print("3");
    // 4) Datos
 /*   final List<Map<String, dynamic>> data =
        List<Map<String, dynamic>>.from(
      await state.widget.api.getList(
        state.widget.entity.name,
        filters: allFilters.isEmpty ? null : allFilters,
      ),
    );
print("4");
    rows = data;*/

 rows = await state.widget.api.getList(
    state.widget.entity.name,
    filters: allFilters.isEmpty ? null : allFilters,
  );
  print("4.1");
    // 5) Columnas
    columns = metadataFields.map((f) {
      return ColumnDefinition(
        field: f.name,
        label: f.label,
        visible: true,
        fieldType: f.fieldType,
      );
    }).toList();

print("Cargando datos de entidad 2: ${state.widget.entity.name}");
print("Filtros aplicados: ${state.widget.parentFilter}");
print("antes de load lookups");

    await loadLookups();
    print("antes de load column visibility");
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

/*Future<void> applyFilter(ColumnFilter filter) async {
 // print("Filtrando por campo: ${filter.field}");
  //print("Campos reales de la fila: ${rows.first.keys}");

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
*/

Future<void> applyFilter(ColumnFilter filter) async {
  columnFilters[filter.field] = filter;

  final columnFiltersJson =
      columnFilters.values.map((f) => f.toJson()).toList();

  final List<Map<String, dynamic>> relationFilters = [];
  if (state.widget.parentFilter != null) {
    state.widget.parentFilter!.forEach((field, value) {
      relationFilters.add({
        "field": field,
        "operator": "equals",
        "value": value,
      });
    });
  }

  final allFilters = [
    ...relationFilters,
    ...columnFiltersJson,
  ];
print("Filtros ALL APPLY: $allFilters");
  rows = await state.widget.api.getList(
    state.widget.entity.name,
    filters: allFilters.isEmpty ? null : allFilters,
  );

  if (!isDisposed && state.mounted) {
    state.setState(() {});
  }
}

/*
 List<Map<String, dynamic>> rows = [];
print("3");
    // 4) Datos
    final List<Map<String, dynamic>> data =
        List<Map<String, dynamic>>.from(
      await state.widget.api.getList(
        state.widget.entity.name,
        filters: allFilters.isEmpty ? null : allFilters,
      ),
    );
print("4");

*/
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

  //String inferType(String field) => inferTypeFromRows(field, rows);
String inferType(String fieldName) {
  final col = columns.firstWhere(
    (c) => c.field == fieldName,
  );

  final t = col.fieldType.toLowerCase();

  // Fechas siempre vienen bien desde metadata
  if (t == "date" || t == "datetime") return "date";

  // Booleanos también
  if (t == "bool" || t == "boolean") return "bool";

  // Lookup
  if (t == "lookup") return "lookup";

  // Para números, metadata NO sirve → inferir desde datos
  final inferred = inferTypeFromRows(fieldName, rows);
  //debugPrint("inferered $inferred");
  if (inferred == "number") return "number";

  return "string";
}}
