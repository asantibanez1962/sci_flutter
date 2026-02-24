import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../models/entity_definition.dart';
import '../../models/field_definition.dart';
import 'dynamic_form_controller.dart';
import 'ui/unsaved_banner.dart';
import 'fields/boolean_field.dart';
import 'fields/lookup_field.dart';
import 'fields/text_field.dart';
import 'fields/number_field.dart';
import 'fields/date_field.dart';
import 'fields/autocomplete_field.dart';

class DynamicFormView extends StatefulWidget {
  final ApiClient api;
  final EntityDefinition entity;
  final Map<String, dynamic>? initialData;
  final Future<void> Function() onClose;
  final Future<bool> Function()? onRequestClose;

  const DynamicFormView({
    super.key,
    required this.api,
    required this.entity,
    required this.initialData,
    required this.onClose,
    this.onRequestClose,
  });

  @override
  DynamicFormViewState createState() => DynamicFormViewState();
}

class DynamicFormViewState extends State<DynamicFormView> {
  late final DynamicFormController controller;

  @override
  void initState() {
    super.initState();
   // debugPrint(">>> DynamicFormView MODULAR ejecutándose para ${widget.entity.name}");


    controller = DynamicFormController(
      api: widget.api,
      entity: widget.entity,
      initialData: widget.initialData,
    );

    controller.loadLookups().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !controller.hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final ok = await attemptClose();
        if (ok) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.entity.displayName),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (controller.hasUnsavedChanges) const UnsavedChangesBanner(),
          Expanded(
            child: ListView(
              children: [
                ...widget.entity.fields.map(
                  (field) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildField(field),
                  ),
                ),
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
    final value = controller.formData[name];
    final modified = controller.isModified(name);

    // lookup: esperar a que carguen
    if (field.dataType == "lookup" && !controller.lookupsLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    // lookup
    if (field.dataType == "lookup") {
      final map = controller.lookupData[name] ?? {};
      return LookupFieldBuilder.buildLookupField(
        context: context,
        field: field,
        value: value,
        lookupMap: map,
        isModified: modified,
        onChanged: (v) {
          setState(() => controller.formData[name] = v);
        },
        loadDialogRows: () async {
          return await widget.api.getLookupRows(
            field.lookupEntity!,
            field.lookupDisplayFields!,
          );
        },
      );
    }

    // boolean
    if (field.fieldType == "boolean") {
      return BooleanField(
        label: field.label,
        value: (value ?? false) as bool,
        modified: modified,
        onChanged: (v) {
          setState(() => controller.formData[name] = v);
        },
      );
    }

if (field.fieldType == "text") {
  return TextFieldWidget(
    label: field.label,
    controller: controller.controllers[name]!,
    modified: modified,
    onChanged: (v) {
      setState(() => controller.formData[name] = v);
    },
  );
}

if (field.fieldType == "number") {
  return NumberFieldWidget(
    label: field.label,
    controller: controller.controllers[name]!,
    modified: modified,
    onChanged: (v) {
      setState(() => controller.formData[name] = v);
    },
  );
}

if (field.fieldType == "date") {
  return DateFieldWidget(
    label: field.label,
    value: value,
    modified: modified,
    onChanged: (v) {
      setState(() => controller.formData[name] = v);
    },
  );
}

if (field.fieldType == "autocomplete") {
  return AutocompleteFieldWidget(
    label: field.label,
    options: field.options ?? [],
    modified: modified,
    onChanged: (v) {
      setState(() => controller.formData[name] = v);
    },
  );
}    // campos normales
 // ⭐ return final obligatorio
  return Text("Tipo no soportado: ${field.fieldType}");

  }

  Future<void> _save() async {
    await controller.save();
    await widget.onClose();
  }

  Future<bool> _confirmExit() async {
    if (!controller.hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Cambios sin guardar"),
        content:
            const Text("Hay cambios sin guardar. ¿Desea salir sin guardar?"),
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
    if (!controller.hasUnsavedChanges) return true;
    return await _confirmExit();
  }
}