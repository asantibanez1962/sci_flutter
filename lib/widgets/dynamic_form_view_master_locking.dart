import 'package:flutter/material.dart';
import 'dynamic_form_view/dynamic_form_view.dart';
import 'dynamic_list_view/dynamic_list_view.dart';
import '../../api/api_client.dart';
import '../../models/entity_definition.dart';
import '../../models/form_metadata.dart';
import '../../models/field_definition.dart';

class DynamicFormViewMasterDetailLocking extends StatefulWidget {
  final FormMetadata metadata;
  final Map<String, dynamic> data;
  final ApiClient api;
  final EntityDefinition entity;
  final Map<String, EntityDefinition> entityMap;

  final Future<void> Function() onClose;
  final Future<bool> Function()? onRequestClose;

  const DynamicFormViewMasterDetailLocking({
    super.key,
    required this.metadata,
    required this.data,
    required this.api,
    required this.entity,
    required this.entityMap,
    required this.onClose,
    this.onRequestClose,
  });

  @override
  State<DynamicFormViewMasterDetailLocking> createState() =>
      DynamicFormViewMasterDetailLockingState();
}

class DynamicFormViewMasterDetailLockingState
    extends State<DynamicFormViewMasterDetailLocking>
    with TickerProviderStateMixin {
  late TabController tabController;

  // ⭐ Necesario para reenviar el cierre al formulario maestro
  final GlobalKey<DynamicFormViewState> _masterFormKey =
      GlobalKey<DynamicFormViewState>();

  @override
  void initState() {
    super.initState();

    tabController = TabController(
      length: 1 + widget.metadata.tabs.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  // =============================================================
  // ⭐ REENVÍO DE CIERRE AL FORMULARIO MAESTRO
  // =============================================================

  Future<bool> _forwardRequestCloseToMaster() async {
    final formState = _masterFormKey.currentState;

    if (formState == null) {
    //  print("MASTERDETAIL: no hay estado del formulario maestro");
      return true;
    }

    final callback = formState.widget.onRequestClose;

    if (callback == null) {
    //  print("MASTERDETAIL: maestro no tiene onRequestClose");
      return true;
    }

    return await callback();
  }

  /// ⭐ Método que debe llamar el TabManager
  Future<bool> handleRequestClose() async {
    //print("handle request close");
  final form = _masterFormKey.currentState;
    if (form == null) return true;

  return await form.handleExternalClose();
}


  // =============================================================
  // UI
  // =============================================================

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTabs(),
        Expanded(child: _buildTabViews()),
      ],
    );
  }

  Widget _buildTabs() {
    return TabBar(
      controller: tabController,
      isScrollable: true,
      labelColor: Colors.blueGrey.shade900,
      unselectedLabelColor: Colors.black54,
      indicatorColor: Colors.blueGrey.shade900,
      tabs: [
        const Tab(text: "General"),
        ...widget.metadata.tabs.map((t) => Tab(text: t.title)),
      ],
    );
  }

  Widget _buildTabViews() {
    return TabBarView(
      controller: tabController,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: _buildMasterForm(),
        ),
        ...widget.metadata.tabs.map((tab) {
          return Padding(
            padding: const EdgeInsets.all(8),
            child: _buildTabContent(tab),
          );
        }),
      ],
    );
  }

  // =============================================================
  // ⭐ TAB GENERAL — FORM MAESTRO CON LOCKING
  // =============================================================

  Widget _buildMasterForm() {
    return DynamicFormView(
      key: _masterFormKey, // ⭐ NECESARIO PARA LOCKING
      api: widget.api,
      entity: widget.entity,
      initialData: widget.data,
      visibleFields: widget.metadata.headerFields,
      onClose: widget.onClose,
      onRequestClose: widget.onRequestClose,
    );
  }

  // =============================================================
  // ⭐ TABS HIJOS — SIN LOCKING
  // =============================================================

  Widget _buildTabContent(FormTabMetadata tab) {
    switch (tab.type) {
      case "form":
        return DynamicFormView(
          api: widget.api,
          entity: widget.entity,
          initialData: widget.data,
          visibleFields: tab.fields,
          onClose: widget.onClose,
          onRequestClose: widget.onRequestClose,
        );

      case "list":
      //print("list");
        final childEntity =
            widget.entityMap[tab.relation!.relatedEntity]!;
        final fk = tab.relation!.foreignKey;
        final pk = widget.entity.primaryKey;
    //    print("Campos de ${childEntity.name}: ${childEntity.fields.map((f) => f.name).join(', ')}");
        final parentId = widget.data[pk] ??
            widget.data[pk.toLowerCase()] ??
            widget.data[pk.toUpperCase()];

        childEntity.fields.removeWhere((f) => f.name == fk);
        
     //   print(">>> ENTITY NAME ENVIADO AL BACKEND: ${childEntity.name}");
        return DynamicListView(
          entity: childEntity,
          api: widget.api,
          hiddenColumns: [fk],
          parentFilter: {
            fk: {
              "logic": "AND",
              "conditions": [
                {"operator": "=", "value": parentId, "value2": null}
              ]
            }
          },
          onEdit: (row) => _openChildPopup(tab, row),
          onCreate: () => _openChildPopup(tab, null),
        );

      default:
        return Center(child: Text("Tipo desconocido: ${tab.type}"));
    }
  }

  // =============================================================
  // ⭐ POPUP HIJO — LOCKING INDEPENDIENTE
  // =============================================================

  Future<void> _openChildPopup(
      FormTabMetadata tab, Map<String, dynamic>? row) async {
    final childEntity = widget.entityMap[tab.relation!.relatedEntity]!;
    final fk = tab.relation!.foreignKey;

    final rawColumns = await widget.api.getColumns(childEntity.name);
    childEntity.fields =
        rawColumns.map((e) => FieldDefinition.fromJson(e)).toList();

    final pk = widget.entity.primaryKey;
    final parentId = widget.data[pk] ??
        widget.data[pk.toLowerCase()] ??
        widget.data[pk.toUpperCase()];

    final initialData = row ?? {fk: parentId};

    if (!mounted) return;
    final formKey = GlobalKey<DynamicFormViewState>();

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
            // ⭐ X DE CIERRE
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

            // ⭐ FORMULARIO
            Expanded(
              child: DynamicFormView(
                key: formKey,
                api: widget.api,
                entity: childEntity,
                initialData: initialData,
                visibleFields: childEntity.fields
                    .where((f) => f.name != fk)
                    .map((f) => f.name)
                    .toList(),

                // ✔ onClose solo para flujos internos (guardar)
                onClose: () async {
                  Navigator.of(context).pop();
                },

                // ✔ onRequestClose (cuando el form pide cerrar)
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
);  }
}