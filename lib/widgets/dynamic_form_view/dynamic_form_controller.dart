import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../models/entity_definition.dart';
import '../../models/field_definition.dart';

class DynamicFormController {
  final ApiClient api;
  final EntityDefinition entity;

  final Map<String, TextEditingController> controllers = {};
  final Map<String, dynamic> formData = {};
  final Map<String, Map<int, String>> lookupData = {};

  bool lookupsLoaded = false;
  late Map<String, dynamic> originalData;
  late final int recordId;
  late String? rowVersion;

  DynamicFormController({
    required this.api,
    required this.entity,
    required Map<String, dynamic>? initialData,
  }) {
    originalData = Map<String, dynamic>.from(initialData ?? {});
    rowVersion = initialData?["rowVersion"];
    recordId = initialData?[entity.primaryKey] ?? 0;
    for (var field in entity.fields) {
      final name = field.name;

      if (_needsController(field)) {
        controllers[name] = TextEditingController(
          text: initialData?[name]?.toString() ?? "",
        );
      }

      formData[name] = initialData?[name];
    }
   
  }

  bool _needsController(FieldDefinition f) {
    return f.fieldType == "text" ||
        f.fieldType == "number" ||
        f.fieldType == "autocomplete";
  }

Future<void> loadRecord() async {
  final pk = entity.primaryKey;
  final id = originalData[pk];

  if (id == null) return;

  //print(">>> Cargando registro real desde backend: ${entity.name} WHERE $pk = $id");

  final fresh = await api.getById(entity.name, id);

  originalData = Map<String, dynamic>.from(fresh);
 // ⭐ Actualizar RowVersion
  rowVersion = fresh["rowVersion"];

  for (var f in entity.fields) {
    final name = f.name;
    final value = fresh[name];

    formData[name] = value;

    if (controllers.containsKey(name)) {
      controllers[name]!.text = value?.toString() ?? "";
    }
  }
}
  Future<void> loadLookups() async {
    for (var f in entity.fields) {
      if (f.dataType == "lookup" && f.lookupEntity != null) {
        final entityName = f.lookupEntity!;
        final url = Uri.parse("${api.baseUrl}/lookup/$entityName");

        final res = await http.get(url);

        if (res.statusCode == 200 && res.body.isNotEmpty) {
          final list = jsonDecode(res.body) as List;

          lookupData[f.name] = {
            for (var item in list)
              item["id"] as int: item["label"] as String,
          };
        } else {
          lookupData[f.name] = {};
        }
      }
    }

    lookupsLoaded = true;
  }

  void syncControllersToFormData() {
    for (var field in entity.fields) {
      if (_needsController(field)) {
        formData[field.name] = controllers[field.name]?.text.trim();
      }
    }
  }

  bool isModified(String name) {
    return formData[name] != originalData[name];
  }

  bool get hasUnsavedChanges {
    for (var key in formData.keys) {
      if (formData[key] != originalData[key]) return true;
    }
    return false;
  }

Future<Map<String, dynamic>> save() async {
  syncControllersToFormData();

  final pk = entity.primaryKey;
  final id = originalData[pk];

  // ⭐ Incluir RowVersion en el payload
  formData["rowVersion"] = rowVersion;

  // ⭐ Llamar al backend
  final result = await api.saveData(
    entity.name,
    formData,
    id: id,
  );

  // ⭐ Conflicto de concurrencia
  if (result["conflict"] == true) {
    return {
      "success": false,
      "conflict": true,
      "currentRowVersion": result["currentRowVersion"],
    };
  }

  // ⭐ Guardado exitoso → actualizar RowVersion
  if (result["success"] == true) {
    rowVersion = result["rowVersion"];
    originalData = Map<String, dynamic>.from(formData);
  }

  return {
    "success": true,
    "conflict": false,
  };
}
void markAllClean() {
  // Copiar el estado actual como el nuevo estado original
  originalData = Map<String, dynamic>.from(formData);

  // Si usás RowVersion, asegurate de mantenerla
  // (ya debería estar actualizada después del save)
}
}