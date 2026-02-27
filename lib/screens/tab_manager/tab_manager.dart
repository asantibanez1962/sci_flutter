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

class TabManager extends StatefulWidget {
  final ApiClient api;
  final List<EntityDefinition> entities;

  const TabManager({
    super.key,
    required this.api,
    required this.entities,
  });

  @override
  State<TabManager> createState() => _TabManagerState();
}

class _TabManagerState extends State<TabManager>
    with TickerProviderStateMixin {
  late TabController controller;
  final List<TabItem> tabs = [];

  bool _restoring = false;

  @override
  void initState() {
    super.initState();

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
    final oldIndex = controller.index;

    controller.dispose();
    controller = TabController(length: tabs.length, vsync: this);

    if (targetIndex != null) {
      controller.index = targetIndex.clamp(0, tabs.length - 1);
    } else {
      controller.index = oldIndex.clamp(0, tabs.length - 1);
    }

    setState(() {});
  }

  
/*
  Future<void> _restoreTabFromId(String id) async {
    if (id == "entities") return;

    if (id.startsWith("list_")) {
      final entityName = id.substring(5);
      final entity = widget.entities.firstWhere((e) => e.name == entityName);
      _openEntityTab(entity, save: false);
      return;
    }

    if (id.startsWith("create_")) {
      final entityName = id.substring(7);
      final entity = widget.entities.firstWhere((e) => e.name == entityName);
      _openCreateTab(entity, save: false);
      return;
    }

    if (id.startsWith("edit_")) {
      final parts = id.split("_");
      if (parts.length < 3) return;

      final entityName = parts[1];
      final recordId = parts[2];

      final entity = widget.entities.firstWhere((e) => e.name == entityName);
      final parsedId = int.tryParse(recordId) ?? recordId;

      final row = await widget.api.getById(entity.name, parsedId);

      _openEditTab(entity, row, save: false);
      return;
    }
  }
*/
  // ----------------- ABRIR PESTAÑAS -----------------
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
          onEdit: (entity, row) => _openEditTab(entity, row),
          onCreate: () => _openCreateTab(entity),
        ),
      ),
    );

if (!_restoring) {
  _rebuildController();

  // ⭐ CAMBIO DE PESTAÑA DESPUÉS DEL FRAME
  WidgetsBinding.instance.addPostFrameCallback((_) {
    controller.index = tabs.length - 1;
    setState(() {});
  });


  if (save) _saveTabs();
}


  }

    void _openEditTab(
    EntityDefinition entity,
    Map<String, dynamic> row, {
    bool save = true,
  }) {

    final tabId = "edit_${entity.name}_${row[entity.primaryKey]}";
    final previousTabIndex = controller.index;
    final formKey = GlobalKey<DynamicFormViewState>();

    tabs.add(
      TabItem(
        id: tabId,
        title: "Editar ${entity.displayName}",
        icon: tabIcon(TabType.edit),
        color: tabColor(TabType.edit),
        closable: true,
        formKey: formKey,
        view: TabViewWrapper( 
          child:DynamicFormView(
              key: formKey,
              api: widget.api,
              entity: entity,
              initialData: row,
              onClose: () async {
                final ok = await formKey.currentState?.attemptClose() ?? true;
                if (!ok) return;
                final editIndex = tabs.indexWhere((t) => t.id == tabId);
                if (editIndex != -1) {
                  _closeTab(editIndex);
                }
                controller.index = previousTabIndex;
                setState(() {});
                }
             ),
            ),
          ),
    );
    if (!_restoring) {
      _rebuildController(targetIndex: tabs.length - 1);
      if (save) _saveTabs();
    }

  }

  void _openCreateTab(EntityDefinition entity, {bool save = true}) {
    final tabId = "create_${entity.name}";

    final previousTabIndex = controller.index;

    final formKey = GlobalKey<DynamicFormViewState>();

    tabs.add(
      TabItem(
        id: tabId,
        title: "Nuevo ${entity.displayName}",
        icon: tabIcon(TabType.create),
        color: tabColor(TabType.create),
        closable: true,
        view: DynamicFormView(
          api: widget.api,
          entity: entity,
          initialData: null,
          key: formKey,
          onClose: () async {
            final ok = await formKey.currentState?.attemptClose() ?? true;
            if (!ok) return;

            final createIndex = tabs.indexWhere((t) => t.id == tabId);
            if (createIndex != -1) {
              _closeTab(createIndex);
            }

             controller.index = previousTabIndex;
             setState(() {});
          },
        ),
      ),
    );

    if (!_restoring) {
      _rebuildController(targetIndex: tabs.length - 1);
      if (save) _saveTabs();
    }
  }

  // ----------------- CERRAR PESTAÑAS -----------------

  void _closeTab(int index) {

    if (index < 0 || index >= tabs.length) return;
    if (!tabs[index].closable) return;

    final oldIndex = controller.index;

    tabs.removeAt(index);

    if (!_restoring) {
      int targetIndex;
      if (tabs.isEmpty) {
        targetIndex = 0;
      } else if (oldIndex >= tabs.length) {
        targetIndex = tabs.length - 1;
      } else {
        targetIndex = oldIndex;
      }

      _rebuildController(targetIndex: targetIndex);
      _saveTabs();
    }

 //   print("Tabs after close: ${tabs.map((t) => t.id).toList()}");
 //   print("Controller index after close = ${controller.index}");
  }

  void _saveTabs() {
    TabPersistence.saveTabs(tabs);
  }



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
            child: t.view,
          )
      ],
    ),
  );
}
/*
  Widget _buildTabContent() {
  return TabBarView(
    controller: controller,
    children: [
      for (final t in tabs)
        KeyedSubtree(
          key: ValueKey(t.id),
          child: t.view,
        )
    ],
  );
}
*/
}