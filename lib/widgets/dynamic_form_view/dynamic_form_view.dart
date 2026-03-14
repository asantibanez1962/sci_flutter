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
import '../../models/master_data/form_section_master_data.dart';
import '../dynamic_form_view_master_data/dynamic_form_section_render.dart';
import '../../models/save_result.dart';



class DynamicFormView extends StatefulWidget {
  final DynamicFormController controller; // ← AGREGAR ESTO
  final ApiClient api;
  final EntityDefinition entity;
  final Map<String, dynamic>? initialData;
  final void Function(Map<String, dynamic> result)? onSaved;
  final Future<void> Function() onClose;
  final Future<bool> Function()? onRequestClose;
  final List<String>? visibleFields;
  final bool showInternalBackButton;
  final Widget Function(
      BuildContext context,
        Widget Function(String fieldName) buildField,
      )? customContentBuilder;

  final List<FormSectionMasterData>? sections;

  const DynamicFormView({
    super.key,
    required this.api,
    required this.entity,
    required this.initialData,
    required this.onClose,
    required this.controller,  // ← AGREGAR ESTO
    this.onSaved,
    this.onRequestClose,
    this.visibleFields,
    this.showInternalBackButton = true, // por defecto TRUE
    this.customContentBuilder,
  this.sections,
  });

  @override
  DynamicFormViewState createState() => DynamicFormViewState();
  
}

class DynamicFormViewState extends State<DynamicFormView> with FormEditingMixin, AutomaticKeepAliveClientMixin{
  //late final DynamicFormController controller;
  late final String sessionId;

    @override
  bool get wantKeepAlive => true;

//  FormMode mode = FormMode.view; se quita por casos de multiples tabs
  Timer? lockRefreshTimer;

  @override
  void initState() {
    super.initState();

    if (widget.controller.mode == FormMode.create) {
        widget.controller.mode = FormMode.edit;
      }

    // 🔥 UNA SESIÓN ÚNICA POR PESTAÑA
  sessionId = const Uuid().v4();
   // 3. Cargar datos
  widget.controller.loadRecord().then((_) {
    // 4. AHORA sí podemos consultar el lock
   // debugPrint("check lock");
    checkExistingLock();
  });

    widget.controller.loadLookups().then((_) {
    //  print("fin lookups");
      if (mounted) setState(() {});
    });
    
  }


  @override
  String get entityName => widget.entity.name;

  @override
  int? get recordId => widget.controller.recordId;

@override
Future<LockResult> acquireLock() async {
  debugPrint(">>> from simple: acquireLock() llamado");
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


  //@override
  //Future<void> releaseLock() => widget.api.releaseLock(entityName, recordId, sessionId);
  @override
Future<void> releaseLock() async {
  //print("FORMVIEW: releaseLock() llamado");
  //print("FORMVIEW: entity=$entityName, record=$recordId, session=$sessionId");

  await widget.api.releaseLock(entityName, recordId, sessionId);

//  print("FORMVIEW: releaseLock() completado");
}

  @override
  Future<void> refreshLock() => widget.api.refreshLock(entityName, recordId, sessionId);

  @override
  Future<void> saveChanges() => _save();

@override
Widget build(BuildContext context) {
  super.build(context); // necesario por AutomaticKeepAlive
  //debugPrint("Entra a Build");
  return PopScope(
    canPop: !widget.controller.hasUnsavedChanges,
    onPopInvokedWithResult: (didPop, result) async {
      if (didPop) return;
      final ok = await attemptClose();
      if (ok) Navigator.pop(context);
    },
    child: Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
          _buildLockBannerFromController(),
//          buildLockBanner(),   // ← Banner del mixin
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildBody() {
  //debugPrint("Entro a Build Body");

  final allFields = widget.entity.fields; // ← List<FieldDefinition>

  final fieldsToShow = widget.visibleFields == null
      ? allFields
      : allFields.where((f) => widget.visibleFields!.contains(f.name)).toList();

 // ⭐⭐ AQUÍ CREAMOS fieldsForThisTab ⭐⭐
  final fieldsForThisTab = widget.sections != null
      ? _getFieldsForTab(widget.sections!, allFields)
      : fieldsToShow;

 /* final fieldsToShow = widget.visibleFields == null
      ? widget.entity.fields
      : widget.entity.fields
          .where((f) => widget.visibleFields!.contains(f.name))
          .toList();*/

  return Padding(
    padding: const EdgeInsets.all(12),
    child: Column(
      children: [
        if (widget.controller.hasUnsavedChanges) const UnsavedChangesBanner(),

        Expanded(
          child: ListView(
            children: [
              if (widget.sections != null)
                  DynamicFormSectionRenderer(
                    sections: widget.sections!,
                    fields: fieldsForThisTab,
                    buildField: (fieldName) {
                      final field = fieldsToShow.firstWhere((f) => f.name == fieldName);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildField(field),
                      );
                    },
                  )
                else
                  ...fieldsToShow.map(
                    (field) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildField(field),
                    ),
                  ),
              /*
              ...fieldsToShow.map(
                (field) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildField(field),
                ),
              ),
*/
              const SizedBox(height: 16),

              // -------------------------------
              // BOTONES SEGÚN EL MODO
              // -------------------------------
              if (widget.controller.mode == FormMode.view)
                SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: () async {
                        //  print("🟦 BOTÓN EDITAR → PRESIONADO");
                        await widget.controller.startEditing();
                        //print("🟦 CONTROLLER MODE DESPUÉS DE startEditing(): ${widget.controller.mode}");
                        setState(() {});
                      },

                    // onPressed: startEditing,
                    child: const Text(
                      "Editar",
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ),

              if (widget.controller.mode == FormMode.edit) ...[
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
  onPressed: () async {
    // 🔥 1. Liberar lock y volver a modo vista
    await widget.controller.cancelEditing();

    // 🔥 2. Refrescar la UI
    if (mounted) setState(() {});

    // 🔥 3. Si DynamicFormView está dentro de MasterData,
    //     NO cerramos aquí. Solo cambiamos modo.
    //     El cierre lo maneja TabManager.
  },
  child: const Text(
    "Cancelar",
    style: TextStyle(fontSize: 13),
  ),
),                ),
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
    final value = widget.controller.formData[name];
    final modified = widget.controller.isModified(name);
    final error = FieldValidator.validate(field, value);
    final isEditable = (widget.controller.mode == FormMode.edit);
    //debugPrint("Field en _buildField: ${field.name} value: ${value} type:${field.dataType}");
    // lookup: esperar a que carguen
    if (field.dataType == "lookup" && !widget.controller.lookupsLoaded) {
     // debugPrint("is lookup");
      return const Center(child: CircularProgressIndicator());
    }

    // lookup
   // lookup
  if (field.dataType == "lookup") {
    final map = widget.controller.lookupData[name] ?? {};
    return LookupFieldBuilder.buildLookupField(
      context: context,
      field: field,
      value: value,
      lookupMap: map,
      isModified: modified,
      enabled: isEditable,                    // ⭐ NUEVO
      onChanged: isEditable
          ? (v) {
              setState(() => widget.controller.formData[name] = v);
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
              setState(() => widget.controller.formData[name] = v);
            }
         : (_){},
    );
  }


if (field.fieldType == "text") {
    return TextFieldWidget(
      label: field.label,
      controller: widget.controller.controllers[name]!,
      modified: modified,
      errorText: error,
      enabled: isEditable,                    // ⭐ NUEVO
      onChanged: isEditable
          ? (v) {
              setState(() {
                widget.controller.formData[name] = v;
              });
            }
          : (_){},
    );
  }

if (field.fieldType == "number") {
    return NumberFieldWidget(
      label: field.label,
      controller: widget.controller.controllers[name]!,
      modified: modified,
      enabled: isEditable,                    // ⭐ NUEVO
      onChanged: isEditable
          ? (v) {
              setState(() => widget.controller.formData[name] = v);
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
              setState(() => widget.controller.formData[name] = iso);
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
              setState(() => widget.controller.formData[name] = v);
            }
          : (_){},
    );
  }

 // ⭐ return final obligatorio
  return Text("Tipo no soportado: ${field.fieldType}");

  }

Widget _buildLockBannerFromController() {
  final c = widget.controller;

  if (!c.isLockedByAnotherUser) return const SizedBox.shrink();

  final elapsed = c.lockedAt != null
      ? formatElapsed(DateTime.now().difference(c.lockedAt!))
      : "";

  return Container(
    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
    decoration: BoxDecoration(
      color: Colors.red.shade100,
      border: Border(
        bottom: BorderSide(color: Colors.red.shade300, width: 0.5),
      ),
    ),
    child: Row(
      children: [
        Icon(Icons.lock, color: Colors.red.shade700, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            "Bloqueado por ${c.lockedBy} — $elapsed",
            style: TextStyle(
              color: Colors.red.shade800,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

List<FieldDefinition> _getFieldsForTab(
  List<FormSectionMasterData> sections,
  List<FieldDefinition> allFields,
) {
  final fieldNamesInTab = sections
      .expand((s) => s.items)
      .where((i) => i.detailType == 'field' && i.fieldName != null)
      .map((i) => i.fieldName!)
      .toSet();

  return allFields.where((f) => fieldNamesInTab.contains(f.name)).toList();
}

Future<bool> handleExternalClose() async {
  final ok = await attemptClose();
  if (!ok) return false;

  if (hasLock) {
  //  print("FORMVIEW: handleExternalClose() → liberando lock");
    await releaseLock();
  }

  //await widget.onClose();
  return true;
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

/*
Future<void> _save() async {
  //final result = await widget.controller.save();
  await widget.controller.save(() async {
  final result = await widget.controller.saveLocal(); // ← tu método viejo
      await _handleSaveResult(result);
  });

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
    widget.controller.rowVersion = result["currentRowVersion"];

    // ⭐ Recargar datos
    await widget.controller.loadRecord();

    setState(() {
      widget.controller.mode = FormMode.view;
    });

    return;
  }

  // ⭐ Guardado exitoso
  setState(() {
    widget.controller.mode = FormMode.view;
    widget.controller.markAllClean();
  });
}

*/

Future<void> _save() async {
  // Llamamos al flujo unificado: FormEditingController.save → DynamicFormController.saveToBackend
  final SaveResult result = await widget.controller.save(
    () => widget.controller.saveToBackend(),
  );

  // -----------------------------
  // CREATE (venía de FormMode.create)
  // -----------------------------
  if (widget.controller.mode == FormMode.view &&
      !result.conflict &&
      widget.controller.recordId != 0 &&
      widget.controller.rowVersion != null) {
    // Caso típico: era CREATE, guardó bien, ahora está en view
    setState(() {
      widget.controller.markAllClean();
    });
    // Notificar al padre que se guardó (importante para la lista)
    if (widget.onSaved != null) {
      widget.onSaved!({
        "success": true,
        "id": result.id,
        "rowVersion": result.rowVersion,
        "data": result.data
      });
    }

    return;
  }

  // -----------------------------
  // EDIT — conflicto de concurrencia
  // -----------------------------
  if (result.conflict) {
    await _showConflictDialog();

    if (result.currentRowVersion != null) {
      widget.controller.rowVersion = result.currentRowVersion;
      await widget.controller.loadRecord();
    }

    setState(() {});
    return;
  }

  // -----------------------------
  // EDIT — éxito normal
  // -----------------------------
  setState(() {
    widget.controller.markAllClean();
  });
}

/*
Future<void> _handleSaveResult(Map<String, dynamic> result) async {
  if (result["conflict"] == true) {
    await _showConflictDialog();

    widget.controller.rowVersion = result["currentRowVersion"];
    await widget.controller.loadRecord();

    setState(() {
      widget.controller.mode = FormMode.view;
    });

    return;
  }

  setState(() {
    widget.controller.mode = FormMode.view;
    widget.controller.markAllClean();
  });
}
*/
Future<void> _showConflictDialog() async {
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
}
  Future<bool> _confirmExit() async {
    if (!widget.controller.hasUnsavedChanges) return true;

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
    final value = widget.controller.formData[field.name];
    final error = FieldValidator.validate(field, value);
    if (error != null) return true;
  }
  return false;
}

Future<bool> attemptClose() async {
  debugPrint("attemptClose de dynamic form view");

  // -----------------------------
  // 1. CREATE → permitir cerrar SIEMPRE
  // -----------------------------
  if (widget.controller.mode == FormMode.create) {
    return true;
  }

  // -----------------------------
  // 2. EDIT → validar errores
  // -----------------------------
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
    return false;
  }

  // -----------------------------
  // 3. EDIT → sin cambios → cerrar
  // -----------------------------
  if (!widget.controller.hasUnsavedChanges) {
    return true;
  }

  // -----------------------------
  // 4. EDIT → con cambios → pedir confirmación
  // -----------------------------
  final confirm = await _confirmExit();
  return confirm;
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

void setExternalMode(FormMode newMode) {
  setState(() {
    mode = newMode;
  });
}
}