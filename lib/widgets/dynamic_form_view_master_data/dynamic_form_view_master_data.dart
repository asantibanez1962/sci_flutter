import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../api/api_client.dart';
import '../../../models/entity_definition.dart';
import '../../../models/field_definition.dart';

import '../dynamic_form_view/dynamic_form_view.dart';
import '../dynamic_form_view/dynamic_form_controller.dart';
import '../dynamic_list_view/dynamic_list_view.dart';

import '../../../models/master_data/form_metadata_master_data.dart';
import '../../../models/master_data/form_tab_master_data.dart';
import '../../../models/master_data/form_section_master_data.dart';
import '../../../models/master_data/form_detail_master_data.dart';
import '../../widgets/dynamic_form_view/ui/unsaved_banner.dart';
import 'master_data_controller.dart';
import '../../models/form_mode.dart';

class DynamicFormViewMasterData extends StatefulWidget {
  final FormMetadataMasterData metadata;
  final Map<String, dynamic> data;
  final ApiClient api;
  final EntityDefinition entity;
  final Map<String, EntityDefinition> entityMap;
  final DynamicFormController controller;
  final Future<void> Function() onClose;
  final Future<bool> Function()? onRequestClose;

  const DynamicFormViewMasterData({
    super.key,
    required this.metadata,
    required this.data,
    required this.api,
    required this.entity,
    required this.entityMap,
    required this.controller,
    required this.onClose,
    this.onRequestClose,
  });

  @override
  State<DynamicFormViewMasterData> createState() =>
      DynamicFormViewMasterDataState();
}

class DynamicFormViewMasterDataState extends State<DynamicFormViewMasterData>
    with TickerProviderStateMixin {
  late TabController tabController;

  // Controlador maestro
  late MasterDataController master;

  // Keys de subforms
  final Map<String, GlobalKey<DynamicFormViewState>> _formKeys = {};

  late FormTabMasterData masterTab;

  // ⭐ MODO GLOBAL
  FormMode mode = FormMode.view;

  @override
  void initState() {
    super.initState();

    master = MasterDataController(formController: widget.controller);

    final tabs = [...widget.metadata.tabs]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    masterTab = tabs.first;

    tabController = TabController(
      length: tabs.length,
      vsync: this,
    );

    _configureMasterController();
  }

  void _configureMasterController() {
    final c = widget.controller;

    c.entityName = widget.entity.name;
    c.recordId = widget.data[widget.entity.primaryKey] ?? 0;

    c.acquireLock = () => widget.api.lockRecord(
          c.entityName,
          c.recordId!,
          c.sessionId,
        );

    c.releaseLock = () => widget.api.releaseLock(
          c.entityName,
          c.recordId!,
          c.sessionId,
        );

    c.refreshLock = () => widget.api.refreshLock(
          c.entityName,
          c.recordId!,
          c.sessionId,
        );

    c.fetchLockStatus = () => widget.api.getLockStatus(
          c.entityName,
          c.recordId!,
        );
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  // ---------------------------------------------
  // EDIT MODE
  // ---------------------------------------------
  Future<void> _enterEditMode() async {
    await master.startEditing();
    setState(() => mode = FormMode.edit);

    // ⭐ Propagar modo a todos los subforms
    for (final key in _formKeys.values) {
      key.currentState?.setExternalMode(FormMode.edit);
      key.currentState?.revalidate();   // ⭐ AGREGADO

    }
  }

  Future<void> _cancelEdit() async {
    await master.cancelEditing();
    setState(() => mode = FormMode.view);

    // ⭐ Propagar modo a todos los subforms
    for (final key in _formKeys.values) {
      key.currentState?.setExternalMode(FormMode.view);
       key.currentState?.revalidate();   // ⭐ AGREGADO

    }
  }

  // ---------------------------------------------
  // GUARDAR GLOBAL
  // ---------------------------------------------
  Future<void> _saveMaster() async {
    final ok = await master.saveMaster();
    if (ok) {
      setState(() => mode = FormMode.view);

      for (final key in _formKeys.values) {
        key.currentState?.setExternalMode(FormMode.view);
         key.currentState?.revalidate();   // ⭐ AGREGADO

      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Guardado correctamente")),
      );
    }
  }

  // ---------------------------------------------
  // UI
  // ---------------------------------------------
@override
Widget build(BuildContext context) {
  final tabs = [...widget.metadata.tabs]
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  return PopScope(
    canPop: !master.hasUnsavedChanges,
    onPopInvokedWithResult: (didPop, result) async {
       print("🔵 PopScope → onPopInvokedWithResult fired");
      print("   didPop=$didPop result=$result");
    print("   master.hasUnsavedChanges=${master.hasUnsavedChanges}");

     if (didPop) {
      print("🔵 PopScope → didPop=true → Flutter ya hizo pop");
      return;
    }


      final ok = await attemptClose();
        print("🔵 PopScope → attemptClose() returned $ok");


      if (ok) {
      print("🔵 PopScope → Navigator.pop()");
      Navigator.pop(context);
    } else {
      print("🔵 PopScope → Cancelled exit");
    }

    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(widget.metadata.displayName),
        actions: [
          if (mode == FormMode.view)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _enterEditMode,
            ),

          if (mode == FormMode.edit)
            AnimatedBuilder(
              animation: master,
              builder: (context, _) {
                return ElevatedButton(
                  onPressed: master.isValid ? _saveMaster : null,
                  child: const Text("Guardar"),
                );
              },
            ),

          if (mode == FormMode.edit)
            TextButton(
              onPressed: _cancelEdit,
              child: const Text("Cancelar"),
            ),

          const SizedBox(width: 12),
        ],
      ),

      body: Column(
        children: [
          if (master.hasUnsavedChanges)
            const Padding(
              padding: EdgeInsets.all(8),
              child: UnsavedChangesBanner(),
            ),

          TabBar(
            controller: tabController,
            isScrollable: true,
            labelColor: Colors.blueGrey.shade900,
            unselectedLabelColor: Colors.black54,
            indicatorColor: Colors.blueGrey.shade900,
            tabs: tabs.map((t) => Tab(text: t.title)).toList(),
          ),

          Expanded(
            child: TabBarView(
              controller: tabController,
              children: tabs.map((tab) {
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: _buildTabContent(tab),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    ),
  );
}
    // ---------------------------------------------
  // TAB CONTENT
  // ---------------------------------------------
  Widget _buildTabContent(FormTabMasterData tab) {
    switch (tab.tabType) {
      case 'form':
        return _buildFormTab(tab);
      case 'list':
        return _buildListTab(tab);
      default:
        return Center(child: Text('Tipo de tab desconocido: ${tab.tabType}'));
    }
  }

  // ---------------------------------------------
  // TAB FORM (SUBFORM)
  // ---------------------------------------------
  Widget _buildFormTab(FormTabMasterData tab) {
    final fieldDetails = tab.sections
        .expand((FormSectionMasterData s) => s.items)
        .where((FormDetailMasterData d) =>
            d.detailType == 'field' && d.fieldName != null)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final visibleFields = fieldDetails.map((d) => d.fieldName!).toList();
    final tabkey = "${widget.entity.name}.${tab.key}";
    final formkey = GlobalKey<DynamicFormViewState>();
    _formKeys[tabkey] = formkey;

    return DynamicFormView(
      controller: widget.controller,
      key: formkey,
      api: widget.api,
      entity: widget.entity,
      initialData: widget.data,
      visibleFields: visibleFields,
      sections: tab.sections,
      isSubForm: true,

      // ⭐ PASAMOS EL MODO GLOBAL
      externalMode: mode,

      // VALIDACIÓN GLOBAL
      onValidationChanged: (hasErrors) {
        // print("MASTER → onValidationChanged(tab=$tabkey, hasErrors=$hasErrors)");
        master.updateTabValidation(tabkey, !hasErrors);
        //master.updateTabValidation(tab.key, !hasErrors);
        
      },

      // SINCRONIZACIÓN GLOBAL DE VALORES
      onValueChanged: (field, value) {
              //   print("MASTER → onValueChanged(tab=$tabkey, $field $value)");
                                        master.updateValue(field, value);
      },

      onClose: () async {
        await widget.onClose();
      },
      onRequestClose: widget.onRequestClose,
    );
  }

  // ---------------------------------------------
  // TAB LIST (DETALLES)
  // ---------------------------------------------
  Widget _buildListTab(FormTabMasterData tab) {
    final listDetail = tab.sections
        .expand((FormSectionMasterData s) => s.items)
        .firstWhere(
          (FormDetailMasterData d) =>
              d.detailType == 'list' || d.detailType == 'grid',
          orElse: () =>
              FormDetailMasterData(detailType: 'list', sortOrder: 0),
        );

    final relatedEntityName = listDetail.relatedEntity ?? '';
    if (relatedEntityName.isEmpty) {
      return const Center(child: Text('Lista sin entidad relacionada'));
    }

    final childEntity = widget.entityMap[relatedEntityName];
    if (childEntity == null) {
      return Center(
          child: Text('Entidad hija no encontrada: $relatedEntityName'));
    }

    final fk = listDetail.foreignKey;
    final pk = widget.entity.primaryKey;
    final parentId = widget.data[pk] ??
        widget.data[pk.toLowerCase()] ??
        widget.data[pk.toUpperCase()];

    if (fk != null) {
      childEntity.fields.removeWhere((f) => f.name == fk);
    }

    return DynamicListView(
      entity: childEntity,
      api: widget.api,
      hiddenColumns: [if (fk != null) fk],
      parentFilter: fk == null
          ? null
          : {
              fk: {
                "logic": "AND",
                "conditions": [
                  {"operator": "=", "value": parentId, "value2": null}
                ]
              }
            },
      onEdit: (row) => _openChildPopup(listDetail, childEntity, row),
      onCreate: () => _openChildPopup(listDetail, childEntity, null),
    );
  }
    // ---------------------------------------------
  // POPUP HIJO
  // ---------------------------------------------
  Future<void> _openChildPopup(
    FormDetailMasterData detail,
    EntityDefinition childEntity,
    Map<String, dynamic>? row,
  ) async {
    final fk = detail.foreignKey;

    final rawColumns = await widget.api.getColumns(childEntity.name);
    childEntity.fields =
        rawColumns.map((e) => FieldDefinition.fromJson(e)).toList();

    final pk = widget.entity.primaryKey;
    final parentId = widget.data[pk] ??
        widget.data[pk.toLowerCase()] ??
        widget.data[pk.toUpperCase()];

    final initialData = row ?? {if (fk != null) fk: parentId};

    if (!mounted) return;

    final formKey = GlobalKey<DynamicFormViewState>();

    final controller = DynamicFormController(
      api: widget.api,
      entity: childEntity,
      initialData: initialData,
    );
    controller.sessionId = const Uuid().v4();
    controller.acquireLock = () => widget.api.lockRecord(
          childEntity.name,
          controller.recordId!,
          controller.sessionId,
        );

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(20),
          child: SizedBox(
            width: 600,
            height: 500,
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () async {
                      final state = formKey.currentState;
                      if (state != null) {
                        final ok = await state.handleExternalClose();
                        if (!ok) return;
                      }
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                Expanded(
                  child: DynamicFormView(
                    controller: controller,
                    key: formKey,
                    api: widget.api,
                    entity: childEntity,
                    initialData: initialData,
                    visibleFields: childEntity.fields
                        .where((f) => f.name != fk)
                        .map((f) => f.name)
                        .toList(),
                    onClose: () async {
                      Navigator.of(context).pop();
                    },
                    onRequestClose: () async {
                      final state = formKey.currentState;
                      if (state != null) {
                        final ok = await state.handleExternalClose();
                        if (!ok) return false;
                      }
                      Navigator.of(context).pop();
                      return true;
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


Future<bool> attemptClose() async {
  // 1) Si no hay cambios → salir directo
  print("🟣 attemptClose() ejecutado en MasterData");
  if (!master.hasUnsavedChanges) return true;

  // 2) Preguntar si quiere salir (aunque haya errores)
  final exit = await _confirmExit();
  if (!exit) return false;

  // 3) Si el master NO es válido → advertir, pero permitir salir
  if (!master.isValid) {
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

Future<bool> _confirmExit() async {
  if (!master.hasUnsavedChanges) return true;

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

}