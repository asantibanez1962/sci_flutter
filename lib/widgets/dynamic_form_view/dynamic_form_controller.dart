import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../models/entity_definition.dart';
import '../../models/field_definition.dart';
import '../../models/form_mode.dart';
import '../dynamic_form_view_master_data/form_edition_controller.dart';
//import '../../models/lock_result.dart';
import '../../models/save_result.dart';
import 'package:uuid/uuid.dart';

class DynamicFormController extends FormEditingController {
  final ApiClient api;
  final EntityDefinition entity;

  final Map<String, TextEditingController> controllers = {};
  final Map<String, dynamic> formData = {};
  final Map<String, Map<int, String>> lookupData = {};

  bool lookupsLoaded = false;
  late Map<String, dynamic> originalData;

  // rowVersion y recordId ya existen en FormEditingController
  // pero aquí los inicializamos correctamente
  DynamicFormController({
    required this.api,
    required this.entity,
    required Map<String, dynamic>? initialData,
  }) {
    sessionId = const Uuid().v4();

    if (initialData == null) {
      // -----------------------------
      // CREATE MODE
      // -----------------------------
      mode = FormMode.create;
      originalData = {};
      formData.clear();
      recordId = 0;
      rowVersion = null;
      formData.remove("rowVersion");
      formData.remove("RowVersion");

    } else {
      // -----------------------------
      // EDIT MODE
      // -----------------------------
      mode = FormMode.view;
      originalData = Map<String, dynamic>.from(initialData);
      formData.addAll(initialData);
      recordId = initialData[entity.primaryKey] ?? 0;
      rowVersion = initialData["rowVersion"];
    }

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

  bool _needsController(FieldDefinition f) {
    return f.fieldType == "text" ||
        f.fieldType == "number" ||
        f.fieldType == "autocomplete";
  }

  // -----------------------------
  // LOAD RECORD (solo EDIT)
  // -----------------------------
 Future<void> loadRecord() async {
  final pk = entity.primaryKey;
  final id = originalData[pk];

  if (id == null) return;

  final fresh = await api.getById(entity.name, id);

  // Normalizar originalData
  originalData = {};

  for (var f in entity.fields) {
    final name = f.name;
    final value = fresh[name];

    // Normalizar null → ""
    final normalized = value ?? "";

    // Guardar en originalData
    originalData[name] = normalized;

    // Guardar en formData
    formData[name] = normalized;

    // Actualizar controllers
    if (controllers.containsKey(name)) {
      controllers[name]!.text = normalized.toString();
    }
  }

  // RowVersion
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
  //print("🔎 Revisando cambios…");

  final fieldNames = entity.fields.map((f) => f.name).toSet();

  for (var key in formData.keys) {

    // 🔥 IGNORAR CAMPOS QUE NO SON DEL FORMULARIO
    if (!fieldNames.contains(key)) continue;

    // 🔥 IGNORAR PRIMARY KEY
    if (key == entity.primaryKey) continue;

    final a = formData[key];
    final b = originalData[key];

    final na = (a == null || a == "") ? "" : a;
    final nb = (b == null || b == "") ? "" : b;

    if (na != nb) {
   //   print("⚠️ CAMBIO DETECTADO en '$key'");
    //  print("   formData[$key]     = '$na' (${na.runtimeType})");
   //   print("   originalData[$key] = '$nb' (${nb.runtimeType})");
      return true;
    }
  }

  //print("✔ Sin cambios");
  return false;
} 
 // -----------------------------
  // SAVE TO BACKEND (UNIFICADO)
  // -----------------------------

Future<SaveResult> saveToBackend() async {
  // 1) sincronizar controles
  syncControllersToFormData();

  // 2) construir payload solo con campos del formulario (defensivo)
  final payload = <String, dynamic>{};
  for (var f in entity.fields) {
    final name = f.name;
    if (formData.containsKey(name)) {
      payload[name] = formData[name];
    }
  }

  final isEdit = (mode == FormMode.edit);

  // 3) limpiar locks por si acaso (no deberían estar en payload porque no son fields)
  payload.remove("LockedByUserId");
  payload.remove("LockedAt");
  payload.remove("LockedSessionId");

  // 4) rowVersion: solo en EDIT, y solo una clave
  if (isEdit) {
    if (rowVersion != null) {
      payload["rowVersion"] = rowVersion; // debe ser la cadena base64 que el backend entiende
    }
  } else {
    // CREATE: asegurarse de no enviar ninguna variante
    payload.remove("rowVersion");
    payload.remove("RowVersion");
    payload.remove("ROWVERSION");
    payload.remove("timestamp");
  }

  // 5) debug: ver exactamente lo que vamos a enviar
  //print("🟩 FINAL PAYLOAD = $payload");
  //print("🟥 JSON enviado = ${jsonEncode(payload)}");

  // 6) enviar la copia limpia
  final result = await api.saveData(
    entity.name,
    payload,
    id: isEdit ? recordId : null,
  );

  // 7) manejar respuesta
  if (result["conflict"] == true) {
    return SaveResult(
      success: false,
      conflict: true,
      currentRowVersion: result["currentRowVersion"],
    );
  }

  if (result["success"] == true) {
    // actualizar rowVersion desde el servidor (debe venir como base64 o como lo devuelva el backend)
    rowVersion = result["rowVersion"];

    // marcar originalData con los valores limpios (si quieres mantener rowVersion en originalData para edit, añade la clave)
    originalData = Map<String, dynamic>.from(payload);

    if (!isEdit) {
      recordId = result["id"];
    }
 // Devolver datos útiles al caller
    return SaveResult(
      success: true,
      conflict: false,
      id: result["id"] ?? recordId,
      rowVersion: result["rowVersion"],
      data: Map<String, dynamic>.from(payload) // o formData según prefieras
    );

   // return SaveResult(success: true, conflict: false); se quita para ver si actualiza la lista
  }

  return SaveResult(success: false, conflict: false);
}

  void markAllClean() {
    originalData = Map<String, dynamic>.from(formData);
  }
}