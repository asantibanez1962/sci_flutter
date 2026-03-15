import 'package:flutter/material.dart';

import '../../../api/api_client.dart';
import '../../../models/entity_definition.dart';
import '../../../models/field_definition.dart';
import '../../../models/form_mode.dart';

import '../dynamic_form_view/dynamic_form_view.dart';
import '../dynamic_form_view/dynamic_form_controller.dart';
import '../dynamic_list_view/dynamic_list_view.dart';

import '../../../models/master_data/form_metadata_master_data.dart';
import '../../../models/master_data/form_tab_master_data.dart';
import '../../../models/master_data/form_section_master_data.dart';
import '../../../models/master_data/form_detail_master_data.dart';
import 'package:uuid/uuid.dart';
//import '../../widgets/dynamic_list_view/dynamic_list_controller.dart';


class DynamicFormViewMasterData extends StatefulWidget {
  final FormMetadataMasterData metadata;
  final Map<String, dynamic> data;
  final ApiClient api;
  final EntityDefinition entity;
  final Map<String, EntityDefinition> entityMap;
  final DynamicFormController controller;
  //final DynamicListController? listController; // <-- nuevo, opcional
  final Future<void> Function() onClose;
  final Future<bool> Function()? onRequestClose;

  const DynamicFormViewMasterData({
    super.key,
    required this.metadata,
    required this.data,
    required this.api,
    required this.entity,
    required this.entityMap,
    required this.onClose,
    required this.controller,
    //this.listController, // <-- nuevo
    this.onRequestClose,
  });

  @override
  State<DynamicFormViewMasterData> createState() =>
      DynamicFormViewMasterDataState();
}

class DynamicFormViewMasterDataState extends State<DynamicFormViewMasterData>
    with TickerProviderStateMixin {
  late TabController tabController;

  // Maestro con locking
  final GlobalKey<DynamicFormViewState> _masterFormKey =
      GlobalKey<DynamicFormViewState>();

  // Keys de todos los tabs tipo form (incluido maestro)
  final Map<String, GlobalKey<DynamicFormViewState>> _formKeys = {};

  late FormTabMasterData masterTab;

Future<bool> handleRequestClose() async {
  final masterState = _masterFormKey.currentState;
  if (masterState == null) return true;
  return await masterState.handleExternalClose();
}
  @override
  void initState() {
    super.initState();

    final tabs = [...widget.metadata.tabs]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    masterTab = tabs.first;
    //debugPrint(masterTab.toString());
    tabController = TabController(
      length: tabs.length,
      vsync: this,
    );
    _configureMasterController(); // 👈 AQUÍ
//se agregan para pobrar caso de create
    _syncAllControllers();
    _syncModesFromMaster();

     // Llamada directa y segura al callback que ya existe
     /*
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      await widget.controller.acquireLock?.call();
      debugPrint('Master: acquireLock called for ${widget.controller.entityName}');
    } catch (e, st) {
      debugPrint('Master: acquireLock failed: $e\n$st');
    }
  });*/
   // Asegurar sincronización inicial
  //widget.controller.syncControllersToFormData();

  }

void _configureMasterController() {
  final c = widget.controller;

  // Identidad del registro
  c.entityName = widget.entity.name;
  c.recordId = widget.data[widget.entity.primaryKey] ?? 0;
  
  // Conexión de locking al backend
  c.acquireLock = () => widget.api.lockRecord(
        c.entityName,
        c.recordId!,
        c.sessionId
      );

  c.releaseLock = () => widget.api.releaseLock(
        c.entityName,
        c.recordId!,
        c.sessionId
      );

  c.refreshLock = () => widget.api.refreshLock(
        c.entityName,
        c.recordId!,
        c.sessionId
      );

  c.fetchLockStatus = () => widget.api.getLockStatus(
        c.entityName,
        c.recordId!,
      );
   debugPrint('Master controller configured: entity=${c.entityName} id=${c.recordId} session=${c.sessionId}');

}

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

 void _syncAllControllers() {
  debugPrint('syncAllControllers START controller=${widget.controller.hashCode}');
  for (var entry in _formKeys.entries) {
    final state = entry.value.currentState;
    debugPrint('  sync tab=${entry.key} state=${state?.hashCode}');
    state?.widget.controller.syncControllersToFormData();
  }
  debugPrint('syncAllControllers END formData=${widget.controller.formData}');
}

 void _syncModesFromMaster() {
  final masterState = _masterFormKey.currentState;
  if (masterState == null) {
    debugPrint('syncModesFromMaster: masterState == null');
    return;
  }

  final masterMode = masterState.mode;
  debugPrint('syncModesFromMaster: masterMode=$masterMode');

  for (var entry in _formKeys.entries) {
    final tabKey = entry.key;
    final key = entry.value;

    if (tabKey == masterTab.key) {
      debugPrint('  skip master tab $tabKey');
      continue;
    }

    final state = key.currentState;
    if (state == null) {
      debugPrint('  tab $tabKey state == null');
      continue;
    }

    debugPrint('  tab $tabKey entity=${state.widget.entity.name}');
    if (state.widget.entity.name == widget.entity.name) {
      debugPrint('    setExternalMode($masterMode) on tab $tabKey');
      state.setExternalMode(masterMode);
    } else {
      debugPrint('    setExternalMode(FormMode.view) on tab $tabKey');
      state.setExternalMode(FormMode.view);
    }
  }
}

  @override
  Widget build(BuildContext context) {
    final tabs = [...widget.metadata.tabs]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    // después de cada frame, sincronizamos modos según el maestro
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncModesFromMaster();
    });

    return Column(
      children: [
        _buildHeader(context),
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
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Row(
        children: [
          Text(
            widget.metadata.displayName,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(width: 8),
          Text(
            '(${widget.metadata.entity})',  //podria ser el entityname
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

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

  // -------------------------------------------------------------
  // TAB FORM
  // -------------------------------------------------------------
  Widget _buildFormTab(FormTabMasterData tab) {
  final fieldDetails = tab.sections
      .expand((FormSectionMasterData s) => s.items)
      .where((FormDetailMasterData d) =>
          d.detailType == 'field' && d.fieldName != null)
      .toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  final visibleFields = fieldDetails.map((d) => d.fieldName!).toList();

  final isMaster = tab.key == masterTab.key;

  final key = isMaster ? _masterFormKey : GlobalKey<DynamicFormViewState>();
  _formKeys[tab.key] = key;

  // 🔥 Usar el controller que viene desde arriba
  final controller = widget.controller;

/*
  // 🔥 Crear controller local (igual que en EDIT y CREATE)
  final controller = DynamicFormController(
    api: widget.api,
    entity: widget.entity,
    initialData: widget.data,
  );*/

  return DynamicFormView(
    controller: controller,   // ← AHORA SÍ
    key: key,
    api: widget.api,
    entity: widget.entity,
    initialData: widget.data,
    visibleFields: visibleFields,
    sections: tab.sections,
    onClose: () async {
      _syncAllControllers();
      await widget.onClose();
    },
    onRequestClose: widget.onRequestClose,
  );
}
/*
  Widget _buildFormTab(FormTabMasterData tab) {
    final fieldDetails = tab.sections
        .expand((FormSectionMasterData s) => s.items)
        .where((FormDetailMasterData d) =>
            d.detailType == 'field' && d.fieldName != null)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    //debugPrint("cantidad de campos form:$fieldDetails.length");
/*      print("=== columns FIELDS ===");
      for (var f in fieldDetails) {
        print("FIELD: ${f.fieldName} | type=${f.detailType} | visible=${f.sectionName}");
      }
      print("========================");*/

    final visibleFields = fieldDetails.map((d) => d.fieldName!).toList();

    final isMaster = tab.key == masterTab.key;

    final key = isMaster ? _masterFormKey : GlobalKey<DynamicFormViewState>();
    _formKeys[tab.key] = key;

    return DynamicFormView(
      controller: widget.controller,   // ← AQUÍ SE PASA
      key: key,
      api: widget.api,
      entity: widget.entity,
      initialData: widget.data,
      visibleFields: visibleFields,
      sections: tab.sections, // ← agregado
      onClose: () async {
        _syncAllControllers();
        await widget.onClose();
      },
      onRequestClose: widget.onRequestClose,
    );
  }
*/
  // -------------------------------------------------------------
  // TAB LIST
  // -------------------------------------------------------------

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

  // =============================================================
  // POPUP HIJO — locking independiente
    // =============================================================

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

  // 🔥 Crear controller local (igual que en EDIT, CREATE y MASTER DATA)
  
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
                  controller: controller,   // ← AHORA SÍ
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


}