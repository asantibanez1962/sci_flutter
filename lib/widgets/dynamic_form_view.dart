import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../models/field_definition.dart';
import '../models/entity_definition.dart';
import '../api/api_client.dart';
import 'dynamic_field_widget.dart';
import 'lookup_autoocomplete.dart';
import 'lookupdialog.dart';

class DynamicFormView extends StatefulWidget {
  final ApiClient api;
  final EntityDefinition entity;
  final Map<String, dynamic>? initialData;
  final VoidCallback onClose;
  final Future<bool> Function()? onRequestClose;

  const DynamicFormView({
    super.key,
    required this.api,
    required this.entity,
    required this.initialData,
    required this.onClose,
    this.onRequestClose, // ⭐ ahora sí

  });
  
  @override
  State<DynamicFormView> createState() => DynamicFormViewState();
}

class DynamicFormViewState extends State<DynamicFormView> {
  final Map<String, TextEditingController> controllers = {};
  final Map<String, dynamic> formData = {};
  // ⭐ Nuevo: cache local de lookups
  final Map<String, Map<int, String>> lookupData = {};
  bool lookupsLoaded = false;
  late Map<String, dynamic> originalData = {};


  @override
  void initState() {
    super.initState();
    originalData = Map<String, dynamic>.from(widget.initialData ?? {});

    for (var field in widget.entity.fields) {
      final name = field.name;

      if (_needsController(field)) {
        controllers[name] = TextEditingController(
          text: widget.initialData?[name]?.toString() ?? "",
        );
      }

      formData[name] = widget.initialData?[name];
    }
     // ⭐ Cargar lookups
    loadLookups();

  }


  bool _needsController(FieldDefinition f) {
    return f.fieldType == "text" ||
           f.fieldType == "number" ||
           f.fieldType == "autocomplete";
  }

  @override
  Widget build(BuildContext context) {
   /* print(">>> FIELDS RECIBIDOS EN FORM: ${widget.entity.fields.length}");
    print(">>> INITIAL DATA: ${widget.initialData}");*/
    return PopScope(
      canPop: !hasUnsavedChanges, // ⭐ bloquea navegación si hay cambios
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return; // Flutter ya manejó el pop
        final ok = await attemptClose();
        if (ok) Navigator.pop(context);

/*
        if (!hasUnsavedChanges) {
          Navigator.pop(context);
          return;
        }

        final exit = await _confirmExit();
        if (exit) {
          Navigator.pop(context);
        }*/
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.entity.displayName),
        ),
        body: _buildBody(),
      ),
    );
    }

    
 Future<void> loadLookups() async {
  for (var f in widget.entity.fields) {
    if (f.dataType == "lookup" && f.lookupEntity != null) {
      final entity = f.lookupEntity!;
      final url = Uri.parse("${widget.api.baseUrl}/lookup/$entity");

      final res = await http.get(url);

      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final list = jsonDecode(res.body) as List;

        lookupData[f.name] = {
          for (var item in list)
            item["id"] as int: item["label"] as String
        };
      } else {
        lookupData[f.name] = {}; // evitar null
      }
    }
  }

  // ⭐ ESTO ES LO QUE FALTABA
  setState(() {
    lookupsLoaded = true;
  });
}
 
 Future<void> _save() async {
  debugPrint("🟦 _save() INICIO");

  for (var field in widget.entity.fields) {
    if (_needsController(field)) {
      formData[field.name] = controllers[field.name]?.text.trim();
    }
  }

  final pk = widget.entity.primaryKey;
  final id = widget.initialData?[pk];

  debugPrint("➡️ Llamando saveData() con id=$id");

  try {
    final result = await widget.api.saveData(
      widget.entity.name,
      formData,
      id: id,
    );

    debugPrint("⬅️ saveData() RESULTADO: $result");
  } catch (e) {
    debugPrint("❌ ERROR en saveData(): $e");
  }

  debugPrint("🟩 Cerrando pestaña de edición...");
  attemptClose(); // en vez de widget.onClose()
  //widget.onClose(); // ← AQUÍ SE CIERRA LA PESTAÑA
}
 
  //_save
Widget _buildBody() {
  return Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        if (hasUnsavedChanges)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  "Hay cambios sin guardar",
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

        Expanded(
          child: ListView(
            children: [
              ...widget.entity.fields.map((field) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildField(field),
                );
              }),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _save,
                child: const Text("Guardar"),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _buildField(FieldDefinition field) {
  final name = field.name;
  final value = formData[name];

 /* print(">>> FIELD ${field.name} lookupDisplayFields = ${field.lookupDisplayFields}");
  print(">>> FIELD ${field.name} dataType = ${field.dataType}");
  print(">>> LOOKUP MAP FOR ${field.name} = ${lookupData[field.name]}");*/
  
  // ⏳ Esperar a que los lookups carguen
  if (field.dataType == "lookup" && !lookupsLoaded) {
    return const Center(child: CircularProgressIndicator());
  }

  // 1️⃣ Lookup complejo (multi-columna con diálogo)
  if (field.dataType == "lookup" && field.lookupDisplayFields != null) {
    final map = lookupData[name] ?? {};

    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: TextEditingController(
              text: map[value] ?? "",
            ),
            readOnly: true,
            decoration: InputDecoration(labelText: field.label,
               border: const OutlineInputBorder(),        // ⭐ agrega el recuadro
               enabledBorder: const OutlineInputBorder(), // ⭐ mantiene estilo uniforme
               disabledBorder: const OutlineInputBorder(),// ⭐ para readOnly
               fillColor: isModified(name) ? Colors.orange.shade100 : null,
               filled: isModified(name),

            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () async {
            final rows = await widget.api.getLookupRows(
                field.lookupEntity!,
                field.lookupDisplayFields!,
              );
              
            final selected = await showDialog(
              context: context,
              builder: (_) => LookupDialog(
                title: field.label,
                rows: rows,
                displayFields: field.lookupDisplayFields!,
              ),
            );

            if (selected != null) {
              setState(() {
                formData[name] = selected["id"];
              });
            }
          },
        ),
      ],
    );
  }

  // 2️⃣ Lookup con autocomplete
  if (field.dataType == "lookup" && field.isAutocomplete) {
    final map = lookupData[name] ?? {};

    return LookupAutocomplete(
      label: field.label,
      lookupMap: map,
      value: value as int?,
      isModified: isModified(name),   

      onChanged: (v) {
        setState(() => formData[name] = v);
      },
    );
  }

  // 3️⃣ Lookup normal (dropdown)
  if (field.dataType == "lookup") {
    final map = lookupData[name] ?? {};

    return DropdownButtonFormField<int>(
      initialValue: value as int?,
      decoration: InputDecoration(labelText: field.label,
      border: const OutlineInputBorder(),
      fillColor: isModified(name) ? Colors.orange.shade100 : null,
      filled: isModified(name),
),
      items: map.entries
          .map((e) => DropdownMenuItem(
                value: e.key,
                child: Text(e.value),
              ))
          .toList(),
      onChanged: (v) {
        setState(() => formData[name] = v);
      },
    );
  }

  // ⭐ Campos normales
  return DynamicFieldWidget(
    label: field.label,
    fieldType: field.fieldType,
    controller: controllers[name],
    value: value,
    options: field.options,
    isModified: isModified(name),   // ⭐ AQUI
    onChanged: (v) {
      setState(() => formData[name] = v);
    },
  );
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

Future<bool> _confirmExit() async {
  if (!hasUnsavedChanges) return true;

  final result = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Cambios sin guardar"),
      content: const Text("Hay cambios sin guardar. ¿Desea salir sin guardar?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancelar"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text("Salir"),
        ),
      ],
    ),
  );

  return result ?? false;
}

Future<bool> attemptClose() async {
  if (!hasUnsavedChanges) return true;

  final exit = await _confirmExit();
  return exit;
}

}