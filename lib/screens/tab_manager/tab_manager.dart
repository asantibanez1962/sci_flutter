import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../models/entity_definition.dart';
import '../entities_screen.dart';
import '../entity_data_screen.dart';
import '../../widgets/dynamic_form_view/dynamic_form_view.dart';
import '../../models/tab_item.dart';
import 'tab_icons.dart';
import 'tab_type.dart';
import 'tab_colors.dart';
import '../../services/tab_persistence.dart';
import 'tab_view_wrapper.dart';
//import '../../widgets/dynamic_form_view_master/dynamicformviewmaster.dart';
//import '../../widgets/dynamic_form_view_master_locking.dart';
import '../../widgets/dynamic_form_view_master_data/dynamic_form_view_master_data.dart';
//import '../../models/form_metadata.dart';
import '../../models/master_data/form_metadata_master_data.dart';
import '../../widgets/dynamic_form_view/dynamic_form_controller.dart';
import 'package:uuid/uuid.dart';
import '../../../models/form_mode.dart';
import '../../../models/lock_result.dart';
import '../../../models/lock_status.dart';
import '../../widgets/dynamic_list_view/dynamic_list_controller.dart';

class TabManager extends StatefulWidget {
  final ApiClient api;
  final List<EntityDefinition> entities;
  final Map<String, EntityDefinition> entityMap;

  const TabManager({
    super.key,
    required this.api,
    required this.entities,
     required this.entityMap,
  });

  @override
  State<TabManager> createState() => _TabManagerState();
}


class _TabManagerState extends State<TabManager>
    with TickerProviderStateMixin {
  late TabController controller;
  final List<TabItem> tabs = [];
late final Map<String, EntityDefinition> entityMap;

  bool _restoring = false;

 // -------------------------
  // Controllers por pestaña
  // -------------------------



void _openCreateTabMaster(
  EntityDefinition entity,
  FormMetadataMasterData metadata, {
  bool save = true,
}) {
  final tabId = "create_${entity.name}";
  final previousTabIndex = controller.index;

  final Map<String, dynamic> emptyData = {};

  final formKey = GlobalKey<DynamicFormViewState>();

  tabs.add(
    TabItem(
      id: tabId,
      title: "Nuevo ${entity.displayName}",
      icon: tabIcon(TabType.create),
      color: tabColor(TabType.create),
      closable: true,
      formKey: formKey,
      builder: () {
        // 🔥 Crear controller local (igual que en EDIT y CREATE)
        final formController = DynamicFormController(
          api: widget.api,
          entity: entity,
          initialData: emptyData,
        );

        return TabViewWrapper(
          child: DynamicFormViewMasterData(
            metadata: metadata,
            data: emptyData,
            api: widget.api,
            entity: entity,
            entityMap: entityMap,
            controller: formController,   // ← AHORA SÍ
            onClose: () async {
              final ok = await formKey.currentState?.attemptClose() ?? true;
              if (!ok) return;
                // 2. 🔥 LIBERAR LOCK ANTES DE CERRAR LA PESTAÑA
            //  await controller.cancelEditing();
              final createIndex = tabs.indexWhere((t) => t.id == tabId);
              if (createIndex != -1) _closeTab(createIndex);

              setState(() {});
            },
          ),
        );
      },
    ),
  );

  if (!_restoring) {
    _rebuildController(targetIndex: tabs.length - 1);
    if (save) _saveTabs();
  }
}

Future<void> openFormForEdit(
  EntityDefinition entity,
  Map<String, dynamic> row)  async {
  //print("open $entity");
  final metadata = await widget.api.getFormMetadata(entity.name);
  //print("metadata $metadata");
  // ⭐ Cargar metadata nuevo ANTES de crear el tab
  final metadataMaster = await widget.api.getFormMetadataMaster(entity.name);
  //print("metadataMaste $metadataMaster");
 // Obtener PK
  final pk = entity.primaryKey;
  final recordId = row[pk];

  // 🔥 Log de apertura del formulario (simple o master)
  widget.api.logUiEvent(
    eventType: "ui.open.form",
    entity: entity.name,
    recordId: recordId,
    details: {
      "mode": "edit",
      "formType": metadataMaster.mode, // simple o master
    },
  );
//print("mode");
   //print(metadataMaster.mode);
  if (metadataMaster.mode == "simple") {
    _openEditTabSimple(entity, row);

  } else {
    _openEditTabMaster(entity, row, metadataMaster);
  }
}

void _openEditTabSimple(EntityDefinition entity, Map<String, dynamic> row)
{
  final tabId = "edit_${entity.name}_${row[entity.primaryKey]}";
  //final previousTabIndex = controller.index;

  final formKey = GlobalKey<DynamicFormViewState>();
        final controller = DynamicFormController(
          api: widget.api,
          entity: entity,
        initialData: row,
        );
          // 🔥 CONFIGURAR LOCKING PARA FORMULARIOS SIMPLES
        controller.entityName = entity.name;
        //controller.recordId = row[entity.primaryKey] ?? 0;
        controller.sessionId = const Uuid().v4();

        controller.acquireLock = () => widget.api.lockRecord(
              controller.entityName,
              controller.recordId!,
              controller.sessionId,
            );

        controller.releaseLock = () => widget.api.releaseLock(
              controller.entityName,
              controller.recordId!,
              controller.sessionId,
            );

        controller.refreshLock = () => widget.api.refreshLock(
              controller.entityName,
              controller.recordId!,
              controller.sessionId,
            );

        controller.fetchLockStatus = () => widget.api.getLockStatus(
              controller.entityName,
              controller.recordId!,
            );


  tabs.add(
    TabItem(
      id: tabId,
      title: "Editar ${entity.displayName}",
      icon: tabIcon(TabType.edit),
      color: tabColor(TabType.edit),
      closable: true,
      formKey: formKey,
    // 🔥 ESTE ES EL CAMBIO CRÍTICO
      controller: controller,

      builder: () {//=> TabViewWrapper(
      debugPrint("Antes de formview simple");
      return TabViewWrapper(
        child: DynamicFormView(
          controller: controller,   // ← AHORA SÍ
          key: formKey,
          api: widget.api,
          entity: entity,
          initialData: row,
          onClose: () async {
            debugPrint("on close ");
            //final ok = await formKey.currentState?.attemptClose() ?? true;
            //if (!ok) return;
              // 2. 🔥 LIBERAR LOCK ANTES DE CERRAR LA PESTAÑA
            //debugPrint("await cancel");
            await controller.cancelEditing();
            //debugPrint("await canceld espues");

            final editIndex = tabs.indexWhere((t) => t.id == tabId);
            if (editIndex != -1) _closeTab(editIndex);
            //controller.index = previousTabIndex;
            setState(() {});
          },
        ),
      );
      },),
  );

  if (!_restoring) {
    _rebuildController(targetIndex: tabs.length - 1);
    _saveTabs();
  }
}

void _openEditTabMaster(
  EntityDefinition entity,
  Map<String, dynamic> row,
  FormMetadataMasterData metadata,
) {
  final tabId = "edit_${entity.name}_${row[entity.primaryKey]}";
  final previousTabIndex = controller.index;

  final masterKey = GlobalKey<DynamicFormViewMasterDataState>();

  tabs.add(
    TabItem(
      id: tabId,
      title: "Editar ${entity.displayName}",
      icon: tabIcon(TabType.edit),
      color: tabColor(TabType.edit),
      closable: true,
      onRequestClose: () async {
        final state = masterKey.currentState;
        if (state == null) return true;
        return await state.handleRequestClose();
      },
      builder: () {
        // 🔥 Crear controller local (igual que en CREATE y EDIT simple)
        final formController = DynamicFormController(
          api: widget.api,
          entity: entity,
          initialData: row,
        );

        return TabViewWrapper(
          child: DynamicFormViewMasterData(
            key: masterKey,
            metadata: metadata,
            data: row,
            api: widget.api,
            entity: entity,
            entityMap: entityMap,
            controller: formController,   // ← AHORA SÍ
            onClose: () async {
              final editIndex = tabs.indexWhere((t) => t.id == tabId);
              if (editIndex != -1) _closeTab(editIndex);
              setState(() {});
            },
            onRequestClose: () async {
              final state = masterKey.currentState;
              if (state == null) return true;
              return await state.handleRequestClose();
            },
          ),
        );
      },
    ),
  );

  if (!_restoring) {
    _rebuildController(targetIndex: tabs.length - 1);
    _saveTabs();
  }
}

// ahora
void _openEditTab(
  EntityDefinition entity,
  Map<String, dynamic> row
) {
  openFormForEdit(entity, row);
}


  @override
  void initState() {
    super.initState();

  widget.api.logUiEvent(
    eventType: "ui.open.app",
    entity: null,
    recordId: null,
    details: {
      "timestamp": DateTime.now().toIso8601String(),
    },
  );


 entityMap = {
    for (var e in widget.entities) e.name: e
  };
//    pestaña fija "Entidades"
    tabs.add(
      TabItem(
        id: "entities",
        title: "Entidades",
        icon: tabIcon(TabType.entities),
        color: tabColor(TabType.entities),
        closable: false,
        view: EntitiesScreen(
          api: widget.api,
          entities: widget.entities,
          onOpenEntity: _openEntityTab,
        ),
      ),
    );

    controller = TabController(length: tabs.length, vsync: this);
  }

  // helper central para recrear controller
  void _rebuildController({int? targetIndex}) {
 
  final old = controller;

  final newIndex = (targetIndex ?? old.index).clamp(0, tabs.length - 1);

  // Crear el nuevo controller
  controller = TabController(
    length: tabs.length,
    vsync: this,
    initialIndex: newIndex,
  );

  // Cambiar índice después de que TabBarView exista
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    controller.index = newIndex;
  });

  // ⭐ Destruir el controller viejo DOS FRAMES después
  WidgetsBinding.instance.addPostFrameCallback((_) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      old.dispose();
    });
  });

  // Reconstruir TabManager UNA sola vez
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) setState(() {});
  });
}
  


  // ----------------- ABRIR PESTAÑAS -----------------
void _openEntityTab(EntityDefinition entity, {bool save = true}) async {
  debugPrint("open entitytab $entity.name");
    final fullEntity = await widget.api.getEntityMetadata(entity.name);
    entity.fields = fullEntity.fields;

    final listId = "list_${entity.name.toLowerCase().trim()}";

    tabs.add(
      TabItem(
        id: listId,
        title: entity.displayName,
        icon: tabIcon(TabType.list),
        color: tabColor(TabType.list),
        closable: true,
        view: EntityDataScreen(
          api: widget.api,
          entity: entity,
          onEdit: (entity, row) => _openEditTab(entity, row),
          onCreate: () => openFormForCreate(entity), //onCreate: () => _openCreateTab(entity),
        ),
      ),
    );

if (!_restoring) {
  _rebuildController(targetIndex: tabs.length - 1);

  // Reconstruir TabManager UNA sola vez
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) setState(() {});
  });

  if (save) _saveTabs();
}

  }

Future<void> openFormForCreate(EntityDefinition entity) async {
  // 1. Obtener metadata para saber si es simple o master
  final metadata = await widget.api.getFormMetadata(entity.name);
  final metadataMaster = await widget.api.getFormMetadataMaster(entity.name);
  // 2. Registrar bitácora
  widget.api.logUiEvent(
    eventType: "ui.open.form",
    entity: entity.name,
    recordId: null,
    details: {
      "mode": "create",
      "formType": metadata.mode, // "simple" o "master"
    },
  );

  // 3. Abrir formulario según tipo
  if (metadata.mode == "simple") {
    _openCreateTab(entity); // tu método actual
  } else {
    _openCreateTabMaster(entity, metadataMaster); // ya lo tenés para master
  }
}

void _openCreateTab(EntityDefinition entity, {bool save = true}) {
  debugPrint("Entro a create tab");
  final tabId = "create_${entity.name}";
  final formKey = GlobalKey<DynamicFormViewState>();

  // 🔥 1. Crear el controller FUERA del builder
  final controller = DynamicFormController(
    api: widget.api,
    entity: entity,
    initialData: null,
  );

  // 🔥 2. Configurar modo CREATE
  controller.mode = FormMode.create;
  controller.entityName = entity.name;
  controller.recordId = null;        // ← importante
  controller.sessionId = const Uuid().v4();

 // 3. En CREATE no hay locking real
  controller.acquireLock = () async => LockResult(
        success: true,
        conflict: false,
      );

  controller.releaseLock = () async => LockResult(
        success: true,
        conflict: false,
      );

  controller.refreshLock = () async => LockResult(
        success: true,
        conflict: false,
      );

  controller.fetchLockStatus = () async => LockStatus(
        locked: false,
        lockedBy: null,
        lockedAt: null,
        sessionId: null,
      );

  // 🔥 4. Agregar el TabItem con el controller REAL
  tabs.add(
    TabItem(
      id: tabId,
      title: "Nuevo ${entity.displayName}",
      icon: tabIcon(TabType.create),
      color: tabColor(TabType.create),
      closable: true,
      formKey: formKey,
      controller: controller,   // ← AHORA SÍ

      builder: () {
        return TabViewWrapper(
          child: DynamicFormView(
            controller: controller,
            key: formKey,
            api: widget.api,
            entity: entity,
            initialData: null,

            // 🔥 5. onClose SOLO valida, NO cierra pestañas
            onClose: () async {
              final ok = await formKey.currentState?.attemptClose() ?? true;
              if (!ok) return;

              // en CREATE no hay lock que liberar
            },
          ),
        );
      },
    ),
  );

  // 🔥 6. Activar la pestaña recién creada
  if (!_restoring) {
    _rebuildController(targetIndex: tabs.length - 1);
    if (save) _saveTabs();
  }
}

  void _saveTabs() {
    TabPersistence.saveTabs(tabs);
  }

Future<void> _closeTab(int index) async {
  //print("⛳ _closeTab($index) INICIO");

  if (index < 0 || index >= tabs.length) {
 //   print("❌ index fuera de rango");
    return;
  }

  final currentTab = tabs[index];
  //print("⛳ currentTab.id = ${currentTab.id}");

  // 1) onRequestClose
  if (currentTab.onRequestClose != null) {
 //   print("⛳ ejecutando onRequestClose");
    final ok = await currentTab.onRequestClose!();
 //   print("⛳ onRequestClose devolvió: $ok");
    if (!ok) return;
  }

  // 3) liberar lock
 // print("⛳ verificando controller en TabItem");
  if (currentTab.controller != null) {
 //   print("⛳ controller encontrado, mode = ${currentTab.controller!.mode}");
    if (currentTab.controller!.mode == FormMode.edit) {
  //    print("⛳ liberando lock con cancelEditing()");
      await currentTab.controller!.cancelEditing();
 //     print("⛳ lock liberado");
    } else {
  //    print("⛳ no está en modo edición, no hay lock que liberar");
    }
  }

  // 4) eliminar pestaña
  //print("⛳ eliminando pestaña");

  final oldIndex = controller.index;
  tabs.removeAt(index);

  setState(() {});

  if (!_restoring) {
    int targetIndex;

    if (tabs.isEmpty) {
      targetIndex = 0;
    } else if (oldIndex >= tabs.length) {
      targetIndex = tabs.length - 1;
    } else if (oldIndex == index) {
      targetIndex = (index - 1).clamp(0, tabs.length - 1);
    } else {
      targetIndex = oldIndex;
    }

    _rebuildController(targetIndex: targetIndex);
    _saveTabs();
  }

  //print("⛳ _closeTab FIN");
}


@override
Widget build(BuildContext context) {
 //print(">>> TabManager.build() ejecutado. Tabs abiertas: ${tabs.map((t) => t.id).toList()}");
  return Scaffold(
    appBar: AppBar(
      title: const Text("ERP Dinámico"),
      bottom: TabBar(
        controller: controller,
        isScrollable: true,
        tabs: [
          for (int i = 0; i < tabs.length; i++)
            Tab(
              child: Row(
                children: [
                  Icon(tabs[i].icon, color: tabs[i].color),
                  const SizedBox(width: 6),
                  Text(tabs[i].title),
                  if (tabs[i].closable)
                    GestureDetector(
                      onTap: () async {
                        final key = tabs[i].formKey;
                        if (key != null) {
                          final ok = await key.currentState?.attemptClose() ?? true;
                          if (!ok) return;
                        }
                        _closeTab(i);
                      },
                      child: const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.close, size: 16),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    ),

    body: TabBarView(
      controller: controller,
      children: [
        for (final t in tabs)
          KeyedSubtree(
            key: ValueKey(t.id),
            child: t.builder != null 
                ? t.builder!()  : t.view!, //t.view,
          )
      ],
    ),
  );
}


}

