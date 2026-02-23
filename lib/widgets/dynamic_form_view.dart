import 'package:flutter/material.dart';
import '../models/field_definition.dart';
import '../models/entity_definition.dart';
import '../api/api_client.dart';
import 'dynamic_field_widget.dart';

class DynamicFormView extends StatefulWidget {
  final ApiClient api;
  final EntityDefinition entity;
  final Map<String, dynamic>? initialData;
  final VoidCallback onClose;

  const DynamicFormView({
    super.key,
    required this.api,
    required this.entity,
    required this.initialData,
    required this.onClose,
  });
  
  @override
  State<DynamicFormView> createState() => _DynamicFormViewState();
}

class _DynamicFormViewState extends State<DynamicFormView> {
  final Map<String, TextEditingController> controllers = {};
  final Map<String, dynamic> formData = {};

  @override
  void initState() {
    super.initState();

    for (var field in widget.entity.fields) {
      final name = field.name;

      if (_needsController(field)) {
        controllers[name] = TextEditingController(
          text: widget.initialData?[name]?.toString() ?? "",
        );
      }

      formData[name] = widget.initialData?[name];
    }
  }


  bool _needsController(FieldDefinition f) {
    return f.fieldType == "text" ||
           f.fieldType == "number" ||
           f.fieldType == "autocomplete";
  }

  @override
  Widget build(BuildContext context) {
    print(">>> FIELDS RECIBIDOS EN FORM: ${widget.entity.fields.length}");
    print(">>> INITIAL DATA: ${widget.initialData}");
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entity.displayName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            ...widget.entity.fields.map((field) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DynamicFieldWidget(
                  label: field.label,
                  fieldType: field.fieldType,
                  controller: controllers[field.name],
                  value: formData[field.name],
                  options: field.options,
                  onChanged: (v) {
                    setState(() {
                      formData[field.name] = v;
                    });
                  },
                ),
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
    );
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
  widget.onClose(); // ← AQUÍ SE CIERRA LA PESTAÑA
}
  //_save
}