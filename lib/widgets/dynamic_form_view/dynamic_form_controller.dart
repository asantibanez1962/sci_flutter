import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../models/entity_definition.dart';
import '../../models/field_definition.dart';
import '../../models/form_mode.dart';
import '../dynamic_form_view_master_data/form_edition_controller.dart';
import '../../models/save_result.dart';
import 'package:uuid/uuid.dart';
import 'validation/field_validator.dart';

class DynamicFormController extends FormEditingController {
  final ApiClient api;
  final EntityDefinition entity;

  final Map<String, TextEditingController> controllers = {};
  Map<String, dynamic> formData = {};
  final Map<String, Map<int, String>> lookupData = {};

  bool lookupsLoaded = false;
  late Map<String, dynamic> originalData;

  // ⭐ NUEVO: errores por campo
  final Map<String, String?> errors = {};

  // ⭐ NUEVO: getter de validez global
  bool get isValid => errors.values.every((e) => e == null);




  DynamicFormController({
    required this.api,
    required this.entity,
    required Map<String, dynamic>? initialData,
  }) {
    sessionId = const Uuid().v4();

    if (initialData == null) {
      mode = FormMode.create;
      originalData = {};
      formData.clear();
      recordId = 0;
      rowVersion = null;
      formData.remove("rowVersion");
      formData.remove("RowVersion");
    } else {
      mode = FormMode.view;
      originalData = Map<String, dynamic>.from(initialData);
      formData.addAll(initialData);
      recordId = initialData[entity.primaryKey] ?? 0;
      rowVersion = initialData["rowVersion"];
    }

    originalmode = mode;

    // Crear controllers
    for (var field in entity.fields) {
      final name = field.name;

      if (_needsController(field)) {
        controllers[name] = TextEditingController(
          text: formData[name]?.toString() ?? "",
        );
      }

      formData[name] = formData[name];
    }
  }


void loadInitialData(Map<String, dynamic> data) {
  formData = Map.from(data);
  originalData = Map.from(data);
    // 🔥 Inicializar los TextEditingController con los valores
  data.forEach((key, value) {
    if (controllers.containsKey(key)) {
      controllers[key]!.text = value?.toString() ?? "";
    }
  });
  
}

  bool _needsController(FieldDefinition f) {
    return f.fieldType == "text" ||
        f.fieldType == "number" ||
        f.fieldType == "autocomplete";
  }

  // ⭐ NUEVO: actualizar errores desde subforms
  void updateErrors(Map<String, String?> newErrors) {
    errors.clear();
    errors.addAll(newErrors);
  }

  // ⭐ NUEVO: actualizar valor desde subforms
  void updateValue(String field, dynamic value) {
    formData[field] = value;
  }

  // -----------------------------
  // LOAD RECORD
  // -----------------------------
  Future<void> loadRecord() async {
    final pk = entity.primaryKey;
    final id = originalData[pk];

    if (id == null) return;

    final fresh = await api.getById(entity.name, id);

    originalData = {};

    for (var f in entity.fields) {
      final name = f.name;
      final value = fresh[name];
      final normalized = value ?? "";

      originalData[name] = normalized;
      formData[name] = normalized;

      if (controllers.containsKey(name)) {
        controllers[name]!.text = normalized.toString();
      }
    }

    rowVersion = fresh["rowVersion"];
  }

  // -----------------------------
  // LOOKUPS
  // -----------------------------
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

  // -----------------------------
  // SYNC CONTROLLERS
  // -----------------------------
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
    final fieldNames = entity.fields.map((f) => f.name).toSet();

    final ignored = <String>{
      entity.primaryKey,
    };

    String normalize(dynamic v) {
      if (v == null) return '';
      if (v is String) return v.trim();
      if (v is bool) return v ? 'true' : 'false';
      if (v is num) return v.toString();
      if (v is DateTime) return v.toIso8601String();
      try {
        return jsonEncode(v);
      } catch (_) {
        return v.toString();
      }
    }

    for (final key in formData.keys) {
      if (!fieldNames.contains(key)) continue;
      if (ignored.contains(key)) continue;

      final aRaw = formData[key];
      final bRaw = originalData.containsKey(key) ? originalData[key] : null;

      dynamic a = aRaw;
      dynamic b = bRaw;

      if (b is Map && b.containsKey('id') && (a is num || a is String)) {
        b = b['id'];
      }
      if (a is Map && a.containsKey('id') && (b is num || b is String)) {
        a = a['id'];
      }

      final na = normalize(a);
      final nb = normalize(b);

      if (na != nb) return true;
    }

    return false;
  }

  // -----------------------------
  // SAVE TO BACKEND
  // -----------------------------
  Future<SaveResult> saveToBackend() async {
    //print("🟡 saveToBackend controller.hashCode = ${this.hashCode}");

    syncControllersToFormData();

    final payload = <String, dynamic>{};
    for (var f in entity.fields) {
      final name = f.name;
      if (formData.containsKey(name)) {
        payload[name] = formData[name];
      }
    }

    final isEdit = (originalmode == FormMode.edit);

    payload.remove("LockedByUserId");
    payload.remove("LockedAt");
    payload.remove("LockedSessionId");

    if (isEdit) {
      if (rowVersion != null) {
        payload["rowVersion"] = rowVersion;
      }
    } else {
      payload.remove("rowVersion");
      payload.remove("RowVersion");
      payload.remove("ROWVERSION");
      payload.remove("timestamp");
    }
      if (isEdit) {
        payload[entity.primaryKey] = recordId;
      }

    final result = await api.saveData(
      entity.name,
      payload,
      id: isEdit ? recordId : null,
    );

    //print("🟥 RESULT EN saveToBackend = $result");

// 🔥 1. Conflicto: tu backend NO usa "conflict", así que lo detectamos por rowVersion nulo
if (result["rowVersion"] == null) {
  return SaveResult(
    success: false,
    conflict: true,
    currentRowVersion: null,
  );
}

// 🔥 2. Éxito: tu backend SIEMPRE devuelve "id" cuando guarda
if (result["id"] != null) {
  //print("Success (insert or update)");

  rowVersion = result["rowVersion"];

  if (!isEdit) {
    final newId = result["id"];
    //print("🟡 newId recibido = $newId");

    recordId = newId;
    this.recordId = newId;
   // print("🟡 recordId asignado = $recordId");

    payload[entity.primaryKey] = newId;
    originalData = Map<String, dynamic>.from(payload);

    mode = FormMode.view;
    originalmode = FormMode.view;
  } else {
    originalData = Map<String, dynamic>.from(payload);
  }

  return SaveResult(
    success: true,
    conflict: false,
    id: result["id"],
    rowVersion: result["rowVersion"],
    data: Map<String, dynamic>.from(payload),
  );
}

/*
    if (result["conflict"] == true) {
      return SaveResult(
        success: false,
        conflict: true,
        currentRowVersion: result["currentRowVersion"],
      );
    }
*/
/*
if (result["success"] == true) {
  print("Success ${isEdit}");
  rowVersion = result["rowVersion"];

  if (!isEdit) {
    // 🔥 1. Obtener el ID real del backend
    final newId = result["id"];

    // 🔥 2. Actualizar el controller REAL
    recordId = newId;
    this.recordId = newId;
    print("🟡 recordId asignado = $recordId");


    // 🔥 3. Actualizar el payload con el ID correcto
    payload[entity.primaryKey] = newId;

    // 🔥 4. Actualizar originalData con el payload completo
    originalData = Map<String, dynamic>.from(payload);

    // 5. Después del INSERT, el formulario queda en modo VIEW
    mode = FormMode.view;
    originalmode = FormMode.view;

  } else {
    // UPDATE normal
    originalData = Map<String, dynamic>.from(payload);
  }


  return SaveResult(
    success: true,
    conflict: false,
    id: result["id"] ?? recordId,
    rowVersion: result["rowVersion"],
    data: Map<String, dynamic>.from(payload),
  );
} 
*/
return SaveResult(success: false, conflict: false);

 }

bool get hasValidationErrors {
  for (var field in entity.fields) {
    final value = formData[field.name];
    final error = FieldValidator.validate(field, value);
    if (error != null) return true;
  }
  return false;
}

  void markAllClean() {
    originalData = Map<String, dynamic>.from(formData);
  }
}