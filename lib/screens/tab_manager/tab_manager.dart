import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../models/entity_definition.dart';
import '../../models/field_definition.dart';
import '../entities_screen.dart';
import '../entity_data_screen.dart';
//import '../../widgets/dynamic_form_view.dart';
import '../../widgets/dynamic_form_view/dynamic_form_view.dart';
import '../../models/tab_item.dart';
import 'tab_icons.dart';
import 'tab_type.dart';
import 'tab_colors.dart';
import '../../services/tab_persistence.dart';

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
  final formKey = GlobalKey<DynamicFormViewState>();

  bool _restoring = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();

    // 1. Pestaña fija "Entidades"
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

    // 2. Controller inicial con la pestaña fija
    controller = TabController(length: tabs.length, vsync: this);

    // 3. Esperar a que las entidades estén cargadas
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _waitForEntities();
    });
  }

  // ----------------------------------------------------
  // ESPERAR A QUE LAS ENTIDADES ESTÉN CARGADAS
  // ----------------------------------------------------
  Future<void> _waitForEntities() async {
    if (_initialized) return;

    // Esperar hasta que entities tenga datos reales
    while (widget.entities.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 50));
    }

    _initialized = true;
    _initTabs();
  }

  // ----------------------------------------------------
  // INICIALIZAR / RESTAURAR PESTAÑAS
  // ----------------------------------------------------
  Future<void> _initTabs() async {
    _restoring = true;

    final ids = await TabPersistence.loadTabIds();

    for (final id in ids) {
      await _restoreTabFromId(id);
    }

    _restoring = false;

    _refreshController();
    _saveTabs();
  }

  // ----------------------------------------------------
  // RECONSTRUIR PESTAÑAS DESDE ID
  // ----------------------------------------------------
  Future<void> _restoreTabFromId(String id) async {
    if (id == "entities") return;

    // LISTA
    if (id.startsWith("list_")) {
      final entityName = id.substring(5);
      final entity = widget.entities.firstWhere((e) => e.name == entityName);
      _openEntityTab(entity, save: false);
      return;
    }

    // CREAR
    if (id.startsWith("create_")) {
      final entityName = id.substring(7);
      final entity = widget.entities.firstWhere((e) => e.name == entityName);
      _openCreateTab(entity, save: false);
      return;
    }

    // EDITAR
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

  // ----------------------------------------------------
  // CONTROLADOR DE TABS
  // ----------------------------------------------------
  void _refreshController() {
    controller.dispose();
    controller = TabController(length: tabs.length, vsync: this);
    setState(() {});
  }

  // ----------------------------------------------------
  // ABRIR PESTAÑAS
  // ----------------------------------------------------
  void _openEntityTab(EntityDefinition entity, {bool save = true}) async{
    // 1) Cargar metadata desde el backend
  final columns = await widget.api.getColumns(entity.name);

  entity.fields = columns.map((c) => FieldDefinition.fromJson(c)).toList();

  // 2) Ahora sí abrir la pestaña

    tabs.add(
      TabItem(
        id: "list_${entity.name}",
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
      _refreshController();
      controller.animateTo(tabs.length - 1);
      if (save) _saveTabs();
    }
  }


void _openEditTab(
  EntityDefinition entity,
  Map<String, dynamic> row, {
  bool save = true,
}) {
  final tabId = "edit_${entity.name}_${row[entity.primaryKey]}";

  // 🔥 Guardamos el ID de la pestaña de lista (NO el índice)
  final listTabId = tabs[controller.index].id;
//para el control de mensaje de cambios antes de cerrar si no están grabados los cambios
  final formKey = GlobalKey<DynamicFormViewState>();

  tabs.add(
    TabItem(
      id: tabId,
      title: "Editar ${entity.displayName}",
      icon: tabIcon(TabType.edit),
      color: tabColor(TabType.edit),
      closable: true,
      formKey: formKey,   // ⭐ AQUI
      view: DynamicFormView(
        key: formKey,     // ⭐ AQUI
        api: widget.api,
        entity: entity,
        initialData: row,
        onClose: () async{
            // 1. Obtener el state del DynamicFormView
             final ok = await formKey.currentState?.attemptClose() ?? true;
            if (!ok) return; // ❌ Usuario canceló

          // 2. Cerrar la pestaña actual
          final editIndex = tabs.indexWhere((t) => t.id == tabId);
          if (editIndex != -1) {
            _closeTab(editIndex);
          }

          // 3. Buscar la pestaña de lista por ID
          final listIndex = tabs.indexWhere((t) => t.id == listTabId);
          if (listIndex != -1) {
            controller.animateTo(listIndex);
          }
        },
      ),
    ),
  );

  if (!_restoring) {
    _refreshController();
    controller.animateTo(tabs.length - 1);
    if (save) _saveTabs();
  }
}
//openedit tab
void _openCreateTab(EntityDefinition entity, {bool save = true}) {
  final tabId = "create_${entity.name}";

  // 🔥 Guardamos el ID de la pestaña de lista (NO el índice)
  final listTabId = tabs[controller.index].id;
//para el control de mensaje de cambios antes de cerrar si no están grabados los cambios
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
            // 1. Obtener el state del DynamicFormView
            final ok = await formKey.currentState?.attemptClose() ?? true;
            if (!ok) return; // ❌ Usuario canceló

          // 2. Cerrar la pestaña actual (la de creación)
          final editIndex = tabs.indexWhere((t) => t.id == tabId);
          if (editIndex != -1) {
            _closeTab(editIndex);
          }

          // 3. Buscar la pestaña de lista por ID
          final listIndex = tabs.indexWhere((t) => t.id == listTabId);
          if (listIndex != -1) {
            controller.animateTo(listIndex);
          }
        },
      ),
    ),
  );

  if (!_restoring) {
    _refreshController();
    controller.animateTo(tabs.length - 1);
    if (save) _saveTabs();
  }
}
//oncreate tab


  // ----------------------------------------------------
  // CERRAR PESTAÑAS
  // ----------------------------------------------------
  void _closeTab(int index) {
  if (index < 0 || index >= tabs.length) return; // ← seguridad extra
  if (!tabs[index].closable) return;

  tabs.removeAt(index);

  if (!_restoring) {
    _refreshController();
    _saveTabs();
  }
}
  // ----------------------------------------------------
  // GUARDAR PESTAÑAS
  // ----------------------------------------------------
  void _saveTabs() {
    TabPersistence.saveTabs(tabs);
  }

  // ----------------------------------------------------
  // UI
  // ----------------------------------------------------
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
                      // Si la vista tiene un onClose, llamarlo
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
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: TabBarView(
          controller: controller,
          children: tabs.map((t) => t.view).toList(),
        ),
      ),
    );
  }
  

}