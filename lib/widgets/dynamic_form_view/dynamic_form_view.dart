import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../api/api_client.dart';
import '../../models/entity_definition.dart';
import '../../models/field_definition.dart';
import '../../models/form_mode.dart';
import '../../models/lock_status.dart';
import '../../models/master_data/form_section_master_data.dart';
import '../../models/save_result.dart';

import 'dynamic_form_controller.dart';
import 'fields/autocomplete_field.dart';
import 'fields/boolean_field.dart';
import 'fields/date_field.dart';
import 'fields/lookup_field.dart';
import 'fields/number_field.dart';
import 'fields/text_field.dart';
import 'ui/unsaved_banner.dart';
import 'validation/field_validator.dart';

import '../dynamic_form_view_master_data/dynamic_form_section_render.dart';
import '../form_editing_mixin.dart';

class DynamicFormView extends StatefulWidget {
  final DynamicFormController controller;
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

  // MODO SUBFORM
  final bool isSubForm;
  final void Function(bool hasErrors)? onValidationChanged;
  final void Function(String field, dynamic value)? onValueChanged;
  final FormMode? externalMode;
  const DynamicFormView({
    super.key,
    required this.api,
    required this.entity,
    required this.initialData,
    required this.onClose,
    required this.controller,
    this.onSaved,
    this.onRequestClose,
    this.visibleFields,
    this.showInternalBackButton = true,
    this.customContentBuilder,
    this.sections,
    this.isSubForm = false,
    this.externalMode,
    this.onValidationChanged,
    this.onValueChanged,
  });

  @override
  DynamicFormViewState createState() => DynamicFormViewState();
}

class DynamicFormViewState extends State<DynamicFormView>
    with FormEditingMixin, AutomaticKeepAliveClientMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final String sessionId;
  late final FormMode originalMode;

  Timer? lockRefreshTimer;


  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    originalMode = widget.controller.mode;

    if (widget.controller.mode == FormMode.create) {
      //debugPrint("cambio modo de create a edit");
      widget.controller.mode = FormMode.edit;
    }
   if (widget.externalMode != null) {
      widget.controller.mode = widget.externalMode!;
    }

    sessionId = const Uuid().v4();

    if (!widget.isSubForm) {
      widget.controller.loadRecord().then((_) {
        checkExistingLock();
      });

      widget.controller.loadLookups().then((_) {
        if (mounted) setState(() {});
      });
    } else {
      widget.controller.loadLookups().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    lockRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  String get entityName => widget.entity.name;

  @override
  int? get recordId => widget.controller.recordId;

  @override
  Future<LockResult> acquireLock() async {
    //debugPrint(">>> from simple: acquireLock() llamado");
    final result =
        await widget.api.lockRecord(entityName, recordId, sessionId);

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
  Future<void> releaseLock() async {
    await widget.api.releaseLock(entityName, recordId, sessionId);
  }

  @override
  Future<void> refreshLock() =>
      widget.api.refreshLock(entityName, recordId, sessionId);

  @override
  Future<void> saveChanges() => _save();

  @override
  Widget build(BuildContext context) {
    super.build(context);

    //debugPrint("DFV(${widget.entity.name}) externalMode=${widget.externalMode} controllerMode=${widget.controller.mode}");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isSubForm && widget.onValidationChanged != null) {
        widget.onValidationChanged!(hasValidationErrors);
      }
    });

    if (widget.isSubForm) {
      return _buildSubFormBody();
    }

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
        body: Column(
          children: [
            _buildLockBannerFromController(),
            Expanded(
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.always,
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubFormBody() {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.always,
      child: _buildBody(hideButtons: true, hideUnsavedBanner: true),
    );
  }

  Widget _buildBody({bool hideButtons = false, bool hideUnsavedBanner = false}) {
    final allFields = widget.entity.fields;

    final fieldsToShow = widget.visibleFields == null
        ? allFields
        : allFields.where((f) => widget.visibleFields!.contains(f.name)).toList();

    final fieldsForThisTab = widget.sections != null
        ? _getFieldsForTab(widget.sections!, allFields)
        : fieldsToShow;

    //debugPrint("modo:");
    //debugPrint(widget.controller.mode.toString());

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          if (!hideUnsavedBanner && widget.controller.hasUnsavedChanges)
            const UnsavedChangesBanner(),
          Expanded(
            child: ListView(
              children: [
                if (widget.sections != null)
                  DynamicFormSectionRenderer(
                    sections: widget.sections!,
                    fields: fieldsForThisTab,
                    buildField: (fieldName) {
                      final field = fieldsToShow
                          .firstWhere((f) => f.name == fieldName);
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
                const SizedBox(height: 16),
                if (!hideButtons) ...[
                  if (widget.controller.mode == FormMode.view)
                    SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        onPressed: () async {
                       //   debugPrint("🟦 BOTÓN EDITAR → PRESIONADO");
                       //   debugPrint("🟣 acquireLock actual: ${widget.controller.acquireLock}");
                      //    debugPrint("🟡 controller.hashCode (EDITAR) = ${widget.controller.hashCode}");
                       //   debugPrint("🟡 recordId (EDITAR) = ${widget.controller.recordId}");

                          await widget.controller.startEditing();
                       //   debugPrint(
                       //       "🟦 CONTROLLER MODE DESPUÉS DE startEditing(): ${widget.controller.mode}");
                          setState(() {});
                        },
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
                          await widget.controller.cancelEditing();
                          if (mounted) setState(() {});
                        },
                        child: const Text(
                          "Cancelar",
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(FieldDefinition field) {
    //print("🟦 Field '${field.name}' → value = ${widget.controller.formData[field.name]}");
    //print("🔧 controller.controllers contains '${field.name}'? ${widget.controller.controllers.containsKey(field.name)}");
    //print("🔧 controller.controllers keys = ${widget.controller.controllers.keys}");
    final name = field.name;
    //final value = widget.controller.formData[name];
    final key = resolveKey(widget.controller.formData, name);
          //_normalizeKey(name);
    final value = widget.controller.formData[key];
    //  print("🟦 Field '$name' → key='$key' → value=$value");

    //final key = _normalizeKey(name);
    //final value = widget.controller.formData[key];

    final modified = widget.controller.isModified(name);
    final error = FieldValidator.validate(field, value);
    //final isEditable = (widget.controller.mode == FormMode.edit);
    //final isEditable = widget.externalMode == FormMode.edit;
    final isEditable = widget.externalMode != null
        ? widget.externalMode == FormMode.edit
        : widget.controller.mode == FormMode.edit;

    //final name = field.name;
    //final key = _normalizeKey(name);
    //final value = widget.controller.formData[key];

    if (field.dataType == "lookup" && !widget.controller.lookupsLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    if (field.dataType == "lookup") {
      //final name = field.name;
      //final key = _normalizeKey(name);
      //final value = widget.controller.formData[key];

      //print("🟦 Lookup '$name' → key='$key' → value=$value");
      //print("🔍 Lookup build → key=$key → value=$value");
      final map = widget.controller.lookupData[name] ?? {};
      return LookupFieldBuilder.buildLookupField(
        //key: ValueKey(value),
        context: context,
        field: field,
        value: value,
        lookupMap: map,
        isModified: modified,
        enabled: isEditable,
        onChanged: isEditable
            ? (v) {
           //   print("🟨 onChanged lookup '$name' → newValue=$v");
            //  print("🟨 formData BEFORE = ${widget.controller.formData}");
                //setState(() => widget.controller.formData[name] = v);
                setState(() => widget.controller.formData[key] = v);
              //  print("🟨 formData AFTER = ${widget.controller.formData}");
                widget.onValueChanged?.call(name, v);
                widget.onValidationChanged?.call(hasValidationErrors);
             //   print("lookup oDFV(${widget.entity.name}) → onChanged → hasErrors = $hasValidationErrors");

              }
            : (_) {},
        loadDialogRows: () async {
          return await widget.api.getLookupRows(
            field.lookupEntity!,
            field.lookupDisplayFields!,
          );
        },
        requestValidation: () {
        //  debugPrint('Parent: requestValidation invoked from lookup $name');
          _formKey.currentState?.validate();
        },
      );
    }

    if (field.fieldType == "boolean" || field.fieldType == "bool") {
       //final name = field.name;
       //final key = _normalizeKey(name);
       //final value = widget.controller.formData[key];

       //print("🟦 Boolean '$name' → key='$key' → value=$value");

      return FormField<bool>(
        initialValue: value as bool?,
        validator: (v) {
          if (v == null && field.isRequired == true) {
            return "Este campo es requerido";
          }
          return null;
        },
        builder: (state) {
          return BooleanField(
            label: field.label,
            value: state.value ?? false,
            modified: modified,
            enabled: isEditable,
            onChanged: (v) {
              state.didChange(v);
              setState(() => widget.controller.formData[name] = v);
              widget.onValueChanged?.call(name, v);
              //widget.onValidationChanged?.call(hasValidationErrors);
              //print("build oDFV(${widget.entity.name}) → onChanged → hasErrors = $hasValidationErrors");

            },
            errorText: state.errorText,
          );
        },
      );
    }

    if (field.fieldType == "text") {
        //final name = field.name;
        //final key = _normalizeKey(name);
        //final value = widget.controller.formData[key];
       //  print("🟦 Field '$name' → key='$key' → value=$value");
      // 🔥 Sincronizar el TextEditingController con el valor real
        if (widget.controller.controllers.containsKey(name)) {
          widget.controller.controllers[name]!.text = value?.toString() ?? "";
        }


      return TextFieldWidget(
        label: field.label,
        controller: widget.controller.controllers[name]!,
        modified: modified,
        enabled: isEditable,
        field: field,
        autovalidateMode: AutovalidateMode.always,
        onChanged: isEditable
            ? (v) {
               // debugPrint("on changed text");
                setState(() {
                  widget.controller.formData[name] = v;
                });
                widget.onValueChanged?.call(name, v);
                // ⭐ Notificar validación global
                //widget.onValidationChanged?.call(hasValidationErrors);
                //debugPrint("text oDFV(${widget.entity.name}) → onChanged → hasErrors = $hasValidationErrors");

            //    debugPrint(
             //       'Field onChanged controller=${widget.controller.hashCode} field=$name value=$v');
              }
            : (_) {},
      );
    }

    if (field.fieldType == "number") {
       //final name = field.name;
       //final key = _normalizeKey(name);
       //final value = widget.controller.formData[key];

       print("🟦 Number '$name' → key='$key' → value=$value");

        // Sincronizar el controller
        if (widget.controller.controllers.containsKey(name)) {
          widget.controller.controllers[name]!.text = value?.toString() ?? "";
        }


      return NumberFieldWidget(
        label: field.label,
        controller: widget.controller.controllers[name]!,
        modified: modified,
        enabled: isEditable,
        onChanged: isEditable
            ? (v) {
                setState(() => widget.controller.formData[name] = v);
                widget.onValueChanged?.call(name, v);
               // widget.onValidationChanged?.call(hasValidationErrors);
                //print("number oDFV(${widget.entity.name}) → onChanged → hasErrors = $hasValidationErrors");

              }
            : (_) {},
      );
    }

    if (field.fieldType == "date") {
    

       // print("🟦 Date '$name' → key='$key' → value=$value");

      return DynamicDateField(
        label: field.label,
        value: value,
        modified: modified,
        errorText: error,
        enabled: isEditable,
        onChanged: isEditable
            ? (iso) {
             // print("on changed");
                setState(() => widget.controller.formData[name] = iso);
                widget.onValueChanged?.call(name, iso);
                //widget.onValidationChanged?.call(hasValidationErrors);
               // print("dateoDFV(${widget.entity.name}) → onChanged → hasErrors = $hasValidationErrors");

              }
            : null,
      );
    }

    if (field.fieldType == "autocomplete") {
      return AutocompleteFieldWidget(
        label: field.label,
        options: field.options ?? [],
        modified: modified,
        enabled: isEditable,
        onChanged: isEditable
            ? (v) {
                setState(() => widget.controller.formData[name] = v);
                widget.onValueChanged?.call(name, v);
              //  widget.onValidationChanged?.call(hasValidationErrors);
              //  print("auto DFV(${widget.entity.name}) → onChanged → hasErrors = $hasValidationErrors");

              }
            : (_) {},
      );
    }

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


String resolveKey(Map<String, dynamic> data, String name) {
  final camel = name[0].toLowerCase() + name.substring(1);
  if (data.containsKey(camel)) return camel;
  if (data.containsKey(name)) return name;
  return camel; // fallback
}

  Map<String, dynamic> getCurrentData() {
    return Map<String, dynamic>.from(widget.controller.formData);
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
      await releaseLock();
    }

    return true;
  }

void revalidate() {
  final hasErrors = hasValidationErrors;
  widget.onValidationChanged?.call(hasErrors);
  //print("DFV(${widget.entity.name}) → revalidate() = $hasErrors");
}

  Future<void> _save() async {
    final SaveResult result = await widget.controller.save(
      () => widget.controller.saveToBackend(),
    );
    //print("save");
    /*
      // 🔥 Si ya existe un ID real, restaurar el acquireLock REAL
        if (widget.controller.recordId != null &&
            widget.controller.recordId! > 0) {
          widget.controller.acquireLock = () => widget.api.lockRecord(
                widget.controller.entityName,
                widget.controller.recordId!,
                widget.controller.sessionId,
              );
        }
    */

    if (widget.controller.mode == FormMode.view &&
        !result.conflict &&
        widget.controller.recordId != 0 &&
        widget.controller.rowVersion != null) {
      setState(() {
        widget.controller.markAllClean();
      });

      if (widget.onSaved != null) {
        widget.onSaved!({
          "success": true,
          "id": result.id,
          "rowVersion": result.rowVersion,
          "data": result.data,
        });
      }

      return;
    }

    if (result.conflict) {
      await _showConflictDialog();

      if (result.currentRowVersion != null) {
        widget.controller.rowVersion = result.currentRowVersion;
        await widget.controller.loadRecord();
      }

      setState(() {});
      return;
    }

    setState(() {
      widget.controller.markAllClean();
    });
  }

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
  //debugPrint("attemptClose de dynamic form view");

  // 1) Si no hay cambios → salir directo
  if (!widget.controller.hasUnsavedChanges) {
    return true;
  }

  // 2) Preguntar si quiere salir (aunque haya errores)
  final exit = await _confirmExit();
  if (!exit) return false;

  // 3) Si hay errores → advertir, pero permitir salir
  if (hasValidationErrors) {
    final force = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Errores en el formulario"),
        content: const Text(
          "El formulario tiene errores. Si sale ahora, perderá los cambios.\n\n¿Desea salir de todos modos?"
        ),
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

    return force ?? false;
  }

  // 4) Si no hay errores → salir normal
  return true;
}


  String? convertDMYtoISO(String? dmy) {
    if (dmy == null || dmy.isEmpty) return null;

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