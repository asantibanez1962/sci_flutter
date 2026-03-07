import 'package:flutter/material.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
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
import 'validation/field_validator.dart';
import '../../models/form_mode.dart';
import '../../models/lock_status.dart';
import '../form_editing_mixin.dart';


class DynamicFormView extends StatefulWidget {
  final ApiClient api;
  final EntityDefinition entity;
  final Map<String, dynamic>? initialData;
  final Future<void> Function() onClose;
  final Future<bool> Function()? onRequestClose;
  final List<String>? visibleFields;

  const DynamicFormView({
    super.key,
    required this.api,
    required this.entity,
    required this.initialData,
    required this.onClose,
    this.onRequestClose,
    this.visibleFields,

  });

  @override
  DynamicFormViewState createState() => DynamicFormViewState();
  
}

class DynamicFormViewState extends State<DynamicFormView> with FormEditingMixin, AutomaticKeepAliveClientMixin{
  late final DynamicFormController controller;
  late final String sessionId;

    @override
  bool get wantKeepAlive => true;

  FormMode mode = FormMode.view;
  Timer? lockRefreshTimer;

  @override
  void initState() {
    super.initState();
    // 🔥 UNA SESIÓN ÚNICA POR PESTAÑA
  sessionId = const Uuid().v4();

    controller = DynamicFormController(
      api: widget.api,
      entity: widget.entity,
      initialData: widget.initialData,
    );

  
   // 3. Cargar datos
  controller.loadRecord().then((_) {
    // 4. AHORA sí podemos consultar el lock
    checkExistingLock();
  });

    controller.loadLookups().then((_) {
      if (mounted) setState(() {});
    });
    
  }


  @override
  String get entityName => widget.entity.name;

  @override
  int get recordId => controller.recordId;

@override
Future<LockResult> acquireLock() async {
  final result = await widget.api.lockRecord(entityName, recordId, sessionId);

  return LockResult(
    success: result.success,
    conflict: result.conflict,
    lockedBy: result.lockedBy,
    lockedAt: result.lockedAt,
  );
}

@override
Future<LockStatus> fetchLockStatus() async {
  return await widget.api.getLockStatus(entityName, recordId);
}


  @override
  Future<void> releaseLock() => widget.api.releaseLock(entityName, recordId, sessionId);

  @override
  Future<void> refreshLock() => widget.api.refreshLock(entityName, recordId, sessionId);

  @override
  Future<void> saveChanges() => _save();

@override
Widget build(BuildContext context) {
  super.build(context); // necesario por AutomaticKeepAlive

  return PopScope(
    canPop: !controller.hasUnsavedChanges,
    onPopInvokedWithResult: (didPop, result) async {
      if (didPop) return;
      final ok = await attemptClose();
      if (ok) Navigator.pop(context);
    },
    child: Scaffold(
      appBar: AppBar(
        toolbarHeight: 42,
        titleTextStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        iconTheme: const IconThemeData(size: 18, color: Colors.black87),
        title: Text(widget.entity.displayName),
      ),

      // ⭐⭐ AQUÍ VA EL BANNER + FORMULARIO ⭐⭐
      body: Column(
        children: [
          buildLockBanner(),   // ← Banner del mixin

          // ⭐ NO usar Expanded aquí
          // porque _buildBody() YA contiene un Expanded interno
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildBody() {
  final fieldsToShow = widget.visibleFields == null
      ? widget.entity.fields
      : widget.entity.fields
          .where((f) => widget.visibleFields!.contains(f.name))
          .toList();

  return Padding(
    padding: const EdgeInsets.all(12),
    child: Column(
      children: [
        if (controller.hasUnsavedChanges) const UnsavedChangesBanner(),

        Expanded(
          child: ListView(
            children: [
              ...fieldsToShow.map(
                (field) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildField(field),
                ),
              ),

              const SizedBox(height: 16),

              // -------------------------------
              // BOTONES SEGÚN EL MODO
              // -------------------------------
              if (mode == FormMode.view)
                SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: startEditing,
                    child: const Text(
                      "Editar",
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ),

              if (mode == FormMode.edit) ...[
                SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: hasValidationErrors ? null : _save,
                    child: const Text(
                      "Guardar",
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    onPressed: cancelEditing,
                    child: const Text(
                      "Cancelar",
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
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
    final error = FieldValidator.validate(field, value);
    final isEditable = (mode == FormMode.edit);

    //print("Field en _buildField: ${field.name} minLength=${field.minLength}");
    // lookup: esperar a que carguen
    if (field.dataType == "lookup" && !controller.lookupsLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    // lookup
   // lookup
  if (field.dataType == "lookup") {
    final map = controller.lookupData[name] ?? {};
    return LookupFieldBuilder.buildLookupField(
      context: context,
      field: field,
      value: value,
      lookupMap: map,
      isModified: modified,
      enabled: isEditable,                    // ⭐ NUEVO
      onChanged: isEditable
          ? (v) {
              setState(() => controller.formData[name] = v);
            }
          : (_){},
      loadDialogRows: () async {
        return await widget.api.getLookupRows(
          field.lookupEntity!,
          field.lookupDisplayFields!,
        );
      },
    );
  }

// boolean
  if (field.fieldType == "boolean" || field.fieldType == "bool") {
    return BooleanField(
      label: field.label,
      value: (value ?? false) as bool,
      modified: modified,
      enabled: isEditable,                    // ⭐ NUEVO
      onChanged: isEditable
          ? (v) {
              setState(() => controller.formData[name] = v);
            }
         : (_){},
    );
  }


if (field.fieldType == "text") {
    return TextFieldWidget(
      label: field.label,
      controller: controller.controllers[name]!,
      modified: modified,
      errorText: error,
      enabled: isEditable,                    // ⭐ NUEVO
      onChanged: isEditable
          ? (v) {
              setState(() {
                controller.formData[name] = v;
              });
            }
          : (_){},
    );
  }

if (field.fieldType == "number") {
    return NumberFieldWidget(
      label: field.label,
      controller: controller.controllers[name]!,
      modified: modified,
      enabled: isEditable,                    // ⭐ NUEVO
      onChanged: isEditable
          ? (v) {
              setState(() => controller.formData[name] = v);
            }
         : (_){},
    );
  }

  if (field.fieldType == "date") {
    return DynamicDateField(
      label: field.label,
      value: value,
      modified: modified,
      errorText: error,
      enabled: isEditable,                    // ⭐ NUEVO
      onChanged: isEditable
          ? (iso) {
              setState(() => controller.formData[name] = iso);
            }
          : null,
    );
  }

  if (field.fieldType == "autocomplete") {
    return AutocompleteFieldWidget(
      label: field.label,
      options: field.options ?? [],
      modified: modified,
      enabled: isEditable,                    // ⭐ NUEVO
      onChanged: isEditable
          ? (v) {
              setState(() => controller.formData[name] = v);
            }
          : (_){},
    );
  }

 // ⭐ return final obligatorio
  return Text("Tipo no soportado: ${field.fieldType}");

  }

/*
void _showLockedPopup(String lockedBy, DateTime? lockedAt) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Registro bloqueado"),
      content: Text("Este registro está siendo editado por $lockedBy."),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Aceptar"),
        ),
      ],
    ),
  );
}
*/

Future<void> _save() async {
  final result = await controller.save();

  // ⭐ Conflicto de concurrencia
  if (result["conflict"] == true) {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Conflicto de edición"),
        content: const Text(
          "Otro usuario modificó este registro.\n"
          "Debes recargar antes de continuar.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Aceptar"),
          ),
        ],
      ),
    );

    // ⭐ Actualizar RowVersion local
    controller.rowVersion = result["currentRowVersion"];

    // ⭐ Recargar datos
    await controller.loadRecord();

    setState(() {
      mode = FormMode.view;
    });

    return;
  }

  // ⭐ Guardado exitoso
  setState(() {
    mode = FormMode.view;
    controller.markAllClean();
  });
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

 bool get hasValidationErrors {
  for (var field in widget.entity.fields) {
    final value = controller.formData[field.name];
    final error = FieldValidator.validate(field, value);
    if (error != null) return true;
  }
  return false;
}

Future<bool> attemptClose() async {
  // 1. Si hay errores de validación → bloquear cierre
  if (hasValidationErrors) {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Errores en el formulario"),
        content: const Text("Corrija los errores antes de cerrar."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Aceptar"),
          ),
        ],
      ),
    );
    return false; // ❌ No permitir cerrar
  }

  // 2. Si NO hay cambios → permitir cerrar
  if (!controller.hasUnsavedChanges) return true;

  // 3. Si hay cambios → pedir confirmación
  return await _confirmExit();
 }

 String? convertDMYtoISO(String? dmy) {
  if (dmy == null || dmy.isEmpty) return null;

  // Si ya es ISO, no tocarlo
  if (dmy.contains("T") && dmy.contains("-")) return dmy;

  try {
    final parts = dmy.split('/');
    if (parts.length != 3) return dmy;

    final day = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final year = int.parse(parts[2]);

    final date = DateTime(year, month, day);
    return date.toIso8601String();
  } catch (_) {
    return dmy;
  }
}


}