import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../api/api_client.dart';
import '../../models/entity_definition.dart';
import '../../models/tab_item.dart';
import '../../models/master_data/form_metadata_master_data.dart';
import '../../models/form_mode.dart';
import '../../models/lock_result.dart';
import '../../models/lock_status.dart';
import '../../services/tab_persistence.dart';
import '../../widgets/dynamic_form_view/dynamic_form_view.dart';
import '../../widgets/dynamic_form_view/dynamic_form_controller.dart';
import '../../widgets/dynamic_form_view_master_data/dynamic_form_view_master_data.dart';
//import '../../widgets/dynamic_list_view/dynamic_list_controller.dart';
import '../entities_screen.dart';
import '../entity_data_screen.dart';
import 'tab_icons.dart';
import 'tab_type.dart';
import 'tab_colors.dart';
import 'tab_view_wrapper.dart';

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

  // ---------------------------------------------------------
  // REBUILD TAB CONTROLLER
  // ---------------------------------------------------------
  void _rebuildController({int? targetIndex}) {
    final old = controller;
    final newIndex = (targetIndex ?? old.index).clamp(0, tabs.length - 1);

    controller = TabController(
      length: tabs.length,
      vsync: this,
      initialIndex: newIndex,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      controller.index = newIndex;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        old.dispose();
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  // ---------------------------------------------------------
  // ABRIR FORMULARIO PARA EDITAR (simple o master)
  // ---------------------------------------------------------
  Future<void> openFormForEdit(
    EntityDefinition entity,
    Map<String, dynamic> row,
  ) async {
    final metadata = await widget.api.getFormMetadata(entity.name);
    final metadataMaster = await widget.api.getFormMetadataMaster(entity.name);

    widget.api.logUiEvent(
      eventType: "ui.open.form",
      entity: entity.name,
      recordId: row[entity.primaryKey],
      details: {
        "mode": "edit",
        "formType": metadataMaster.mode,
      },
    );

    if (metadataMaster.mode == "simple") {
      _openEditTabSimple(entity, row);
    } else {
      _openEditTabMaster(entity, row, metadataMaster);
    }
  }

  // ---------------------------------------------------------
  // EDIT SIMPLE
  // ---------------------------------------------------------
  void _openEditTabSimple(EntityDefinition entity, Map<String, dynamic> row) {
    final tabId = "edit_${entity.name}_${row[entity.primaryKey]}";
    final formKey = GlobalKey<DynamicFormViewState>();

    final controller = DynamicFormController(
      api: widget.api,
      entity: entity,
      initialData: row,
    );

    controller.mode = FormMode.view;
    controller.originalmode = FormMode.edit;
    controller.entityName = entity.name;
    controller.sessionId = const Uuid().v4();
    controller.recordId = row[entity.primaryKey] ?? 0;

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
        controller: controller,
        builder: () {
          return TabViewWrapper(
            child: DynamicFormView(
              controller: controller,
              key: formKey,
              api: widget.api,
              entity: entity,
              initialData: row,
              onClose: () async {
                final ok = await formKey.currentState?.attemptClose() ?? true;
                if (!ok) return;

                await controller.cancelEditing();

                final editIndex = tabs.indexWhere((t) => t.id == tabId);
                if (editIndex != -1) _closeTab(editIndex);

                setState(() {});
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

  // ---------------------------------------------------------
  // EDIT MASTER
  // ---------------------------------------------------------
  void _openEditTabMaster(
    EntityDefinition entity,
    Map<String, dynamic> row,
    FormMetadataMasterData metadata,
  ) {
    final tabId = "edit_${entity.name}_${row[entity.primaryKey]}";

    final controller = DynamicFormController(
      api: widget.api,
      entity: entity,
      initialData: row,
    );

    controller.mode = FormMode.view;
    controller.originalmode = FormMode.edit;
    controller.entityName = entity.name;
    controller.recordId = row[entity.primaryKey] ?? 0;
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
        controller: controller,
        closable: true,
        onRequestClose: () async => true,
        builder: () {
          return TabViewWrapper(
            child: DynamicFormViewMasterData(
              metadata: metadata,
              data: row,
              api: widget.api,
              entity: entity,
              entityMap: entityMap,
              controller: controller,
              onClose: () async {
                try {
                  await controller.cancelEditing();
                } catch (_) {}

                final editIndex = tabs.indexWhere((t) => t.id == tabId);
                if (editIndex != -1) _closeTab(editIndex);

                setState(() {});
              },
              onRequestClose: () async => true,
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

  // ---------------------------------------------------------
  // OPEN ENTITY TAB
  // ---------------------------------------------------------
  void _openEntityTab(EntityDefinition entity, {bool save = true}) async {
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
          onEdit: (entity, row) => openFormForEdit(entity, row),
          onCreate: () => openFormForCreate(entity),
        ),
      ),
    );

    if (!_restoring) {
      _rebuildController(targetIndex: tabs.length - 1);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });

      if (save) _saveTabs();
    }
  }

  // ---------------------------------------------------------
  // OPEN FORM FOR CREATE
  // ---------------------------------------------------------
  Future<void> openFormForCreate(EntityDefinition entity) async {
    final metadata = await widget.api.getFormMetadata(entity.name);
    final metadataMaster = await widget.api.getFormMetadataMaster(entity.name);

    widget.api.logUiEvent(
      eventType: "ui.open.form",
      entity: entity.name,
      recordId: null,
      details: {
        "mode": "create",
        "formType": metadata.mode,
      },
    );

    if (metadata.mode == "simple") {
      _openCreateTab(entity);
    } else {
      _openCreateTabMaster(entity, metadataMaster);
    }
  }

  // ---------------------------------------------------------
  // CREATE SIMPLE
  // ---------------------------------------------------------
  void _openCreateTab(EntityDefinition entity, {bool save = true}) {
    final tabId = "create_${entity.name}";
    final formKey = GlobalKey<DynamicFormViewState>();

    final controller = DynamicFormController(
      api: widget.api,
      entity: entity,
      initialData: null,
    );

    controller.mode = FormMode.create;
    controller.originalmode= FormMode.create;
    controller.entityName = entity.name;
    controller.recordId = null;
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
        title: "Nuevo ${entity.displayName}",
        icon: tabIcon(TabType.create),
        color: tabColor(TabType.create),
        closable: true,
        formKey: formKey,
        controller: controller,
        builder: () {
          return TabViewWrapper(
            child: DynamicFormView(
              controller: controller,
              key: formKey,
              api: widget.api,
              entity: entity,
              initialData: null,
              onClose: () async {
                final ok = await formKey.currentState?.attemptClose() ?? true;
                if (!ok) return;

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

  // ---------------------------------------------------------
  // CREATE MASTER
  // ---------------------------------------------------------
  void _openCreateTabMaster(
    EntityDefinition entity,
    FormMetadataMasterData metadata, {
    bool save = true,
  }) {
    final tabId = "create_${entity.name}";
    final Map<String, dynamic> emptyData = {};

    final controller = DynamicFormController(
      api: widget.api,
      entity: entity,
      initialData: null,
    );

    controller.mode = FormMode.create;
    controller.entityName = entity.name;
    controller.recordId = null;
    controller.sessionId = const Uuid().v4();

    controller.acquireLock = () async => LockResult(success: true, conflict: false);
    controller.releaseLock = () async => LockResult(success: true, conflict: false);
    controller.refreshLock = () async => LockResult(success: true, conflict: false);
    controller.fetchLockStatus = () async => LockStatus(
          locked: false,
          lockedBy: null,
          lockedAt: null,
          sessionId: null,
        );

    tabs.add(
      TabItem(
        id: tabId,
        title: "Nuevo ${entity.displayName}",
        icon: tabIcon(TabType.create),
        color: tabColor(TabType.create),
        closable: true,
        controller: controller,
        onRequestClose: () async => true,
        builder: () {
          return TabViewWrapper(
            child: DynamicFormViewMasterData(
              metadata: metadata,
              data: emptyData,
              api: widget.api,
              entity: entity,
              entityMap: entityMap,
              controller: controller,
              onClose: () async {
                try {
                  await controller.cancelEditing();
                } catch (_) {}

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

  // ---------------------------------------------------------
  // CLOSE TAB
  // ---------------------------------------------------------
  Future<void> _closeTab(int index) async {
    if (index < 0 || index >= tabs.length) return;

    final currentTab = tabs[index];

    if (currentTab.onRequestClose != null) {
      final ok = await currentTab.onRequestClose!();
      if (!ok) return;
    }

    if (currentTab.controller != null) {
      if (currentTab.controller!.mode == FormMode.edit) {
        await currentTab.controller!.cancelEditing();
      }
    }

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
  }

  // ---------------------------------------------------------
  // SAVE TABS
  // ---------------------------------------------------------
  void _saveTabs() {
    TabPersistence.saveTabs(tabs);
  }

  // ---------------------------------------------------------
  // BUILD UI
  // ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {
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
                          if (tabs[i].formKey != null) {
                            final ok = await tabs[i]
                                    .formKey!
                                    .currentState
                                    ?.attemptClose() ??
                                true;
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
              child: t.builder != null ? t.builder!() : t.view!,
            )
        ],
      ),
    );
  }
}