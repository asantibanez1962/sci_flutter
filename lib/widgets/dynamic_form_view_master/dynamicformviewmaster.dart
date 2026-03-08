import 'package:flutter/material.dart';
import '../dynamic_form_view/dynamic_form_view.dart';
import '../dynamic_list_view/dynamic_list_view.dart';
import '../../api/api_client.dart';
import '../../models/entity_definition.dart';
import '../../models/form_metadata.dart';
import '../../models/field_definition.dart';

/// ------------------------------------------------------------
/// WIDGET PRINCIPAL: DynamicFormViewMaster
/// ------------------------------------------------------------
class DynamicFormViewMaster extends StatefulWidget {
  final FormMetadata metadata;
  final Map<String, dynamic> data; // registro principal
  final ApiClient api;
  final EntityDefinition entity;
  final Map<String, EntityDefinition> entityMap; // entidades hijas
  final Future<void> Function() onClose;
  final Future<bool> Function()? onRequestClose;

  // callbacks opcionales para listas
  final Function(FormTabMetadata tab, Map<String, dynamic> row)? onEditChild;
  final Function(FormTabMetadata tab)? onCreateChild;

  const DynamicFormViewMaster({
    super.key,
    required this.metadata,
    required this.data,
    required this.api,
    required this.entity,
    required this.entityMap,
    required this.onClose,
    this.onRequestClose,
    this.onEditChild,
    this.onCreateChild,
  });

  @override
  State<DynamicFormViewMaster> createState() => _DynamicFormViewMasterState();
}

class _DynamicFormViewMasterState extends State<DynamicFormViewMaster>
    with TickerProviderStateMixin {
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    // 1 (General) + N tabs dinámicos
    tabController = TabController(
      length: 1 + widget.metadata.tabs.length,
      vsync: this,
    );
    tabController.addListener(() {
  // Evitar logs mientras el usuario está arrastrando
  if (tabController.indexIsChanging) return;

  // Tab 0 = General → no logueamos
  if (tabController.index == 0) return;

  // Tab dinámico seleccionado
  final tab = widget.metadata.tabs[tabController.index - 1];

  // Obtener parentId del registro maestro
  final pk = widget.entity.primaryKey;
  final parentId = widget.data[pk]
      ?? widget.data[pk.toLowerCase()]
      ?? widget.data[pk.toUpperCase()];

  widget.api.logUiEvent(
    eventType: "ui.open.tab",
    entity: widget.entity.name,
    details: {
      "tab": tab.key,
      "parentId": parentId,
    },
  );
});
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTabs(),
        Expanded(child: _buildTabViews()),
      ],
    );
  }

  /// ------------------------------------------------------------
  /// ENCABEZADO DINÁMICO (usado como TAB "General")
  /// ------------------------------------------------------------
Widget _buildHeader() {
  return DynamicFormView(
    api: widget.api,
    entity: widget.entity,
    initialData: widget.data,
    visibleFields: widget.metadata.headerFields,
    onClose: widget.onClose,
    onRequestClose: widget.onRequestClose,
  );
}

  /// ------------------------------------------------------------
  /// TABS ARRIBA (SAP / Odoo)
  /// ------------------------------------------------------------
  Widget _buildTabs() {
    return TabBar(
      controller: tabController,
      isScrollable: true,
      labelColor: Colors.blueGrey.shade900,
      unselectedLabelColor: Colors.black54,
      indicatorColor: Colors.blueGrey.shade900,
      tabs: [
        const Tab(text: "General"), // ← Header como primer tab
        ...widget.metadata.tabs.map((t) => Tab(text: t.title)), //.toList(),
      ],
    );
  }

  /// ------------------------------------------------------------
  /// CONTENIDO DE CADA TAB
  /// ------------------------------------------------------------
  Widget _buildTabViews() {
    // print("🟧 TabBarView children count = ${1 + widget.metadata.tabs.length}");
    //print("🟧 TabBar tabs count = ${tabController.length}");

    return TabBarView(
      controller: tabController,
      children: [
        // TAB 0 → HEADER / GENERAL
        Padding(
          padding: const EdgeInsets.all(8),
          child: _buildHeader(),
        ),

        // TAB 1..N → TABS DINÁMICOS
        ...widget.metadata.tabs.map((tab) {
          return Padding(
            padding: const EdgeInsets.all(8),
            child: _buildTabContent(tab),
          );
        }),
      ],
    );
  }

  /// ------------------------------------------------------------
  /// RENDERIZAR TAB SEGÚN TIPO
  /// ------------------------------------------------------------
  Widget _buildTabContent(FormTabMetadata tab) {

    //print("🟥 DATA DEL MAESTRO:");
    //widget.data.forEach((k, v) => print("   $k = $v"));

    switch (tab.type) {
      case "form":
        if (tab.fields.isEmpty) {
          return const SizedBox.shrink(); // evita crash si no hay fields
        }
        return DynamicFormView(
          api: widget.api,
          entity: widget.entity,
          initialData: widget.data,
          onClose: widget.onClose,
          onRequestClose: widget.onRequestClose,
          visibleFields: tab.fields,
        );

      case "list":
      /*  print("🟦 Entrando a LIST TAB");
        print("   tab.key = ${tab.key}");
        print("   tab.type = ${tab.type}");
        print("   tab.fields = ${tab.fields}");
        print("   tab.columns = ${tab.columns}");
        print("   tab.relation = ${tab.relation}");
        print("   entityMap = ${widget.entityMap.keys.toList()}");
        print("   relatedEntity = ${tab.relation?.relatedEntity}");
        print("   foreignKey = ${tab.relation?.foreignKey}");
          print("   parentId (by FK) = ${widget.data[tab.relation?.foreignKey]}");*/

        // ENTIDAD HIJA CORRECTA: usa relatedEntity, NO fieldName
        final childEntity =
            widget.entityMap[tab.relation!.relatedEntity]!; // ← Contacto
            final fk = tab.relation!.foreignKey; // "SocioNegocioId"
            final pk = widget.entity.primaryKey; // "Id"
            final parentId = widget.data[pk] 
              ?? widget.data[pk.toLowerCase()] 
              ?? widget.data[pk.toUpperCase()];
            /*      print(            "TAB: ${tab.key} → entidad hija: ${childEntity.name}, FK: $fk, parentId: $parentId");
                 print("🟩 Construyendo DynamicListView con:");
                 print("   entity = ${childEntity.name}");
                  print("   parentFilter = { $pk: $parentId }");*/
              // Ocultar la FK en el grid

            childEntity.fields.removeWhere((f) => f.name == fk);

            return DynamicListView(
                entity: childEntity,
                api: widget.api,
                hiddenColumns: [fk], 
                parentFilter: {
                fk: {
                  "logic": "AND",
                  "conditions": [
                      {
                        "operator": "=",
                        "value": parentId,
                        "value2": null
                      }
                    ]
                  }
          },
            //  onEdit: (row) => widget.onEditChild?.call(tab, row),
             // onCreate: () => widget.onCreateChild?.call(tab),
            onEdit: (row) => _openChildPopup(tab, row),
            onCreate: () => _openChildPopup(tab, null),
          );     

      case "grid":
        return const Center(
          child: Text("Grid editable pendiente"),
        );

      default:
        return Center(
          child: Text("Tipo de tab desconocido: ${tab.type}"),
        );
    }
  }



Future<void> _openChildPopup(dynamic tab, Map<String, dynamic>? row) async {
  final childEntity = widget.entityMap[tab.relation!.relatedEntity]!;
  final fk = tab.relation!.foreignKey;

  // 1. Cargar metadata del hijo
  final rawColumns = await widget.api.getColumns(childEntity.name);
  childEntity.fields =
      rawColumns.map((e) => FieldDefinition.fromJson(e)).toList();

  // 2. Ocultar la FK
  //childEntity.fields.removeWhere((f) => f.name == fk);  no funciona luego crear un registro nuevo, porque el form espera ese campo aunque sea hidden. Mejor dejarlo y solo ocultar en el grid.
  // NO eliminar la FK de metadata
// Solo excluirla de visibleFields



  // 3. Preparar initialData
  final pk = widget.entity.primaryKey;
  final parentId = widget.data[pk]
      ?? widget.data[pk.toLowerCase()]
      ?? widget.data[pk.toUpperCase()];

  final initialData = row ?? { fk: parentId };
  widget.api.logUiEvent(
  eventType: "ui.open.child.form",
  entity: childEntity.name,
  recordId: row?["Id"],
  details: {
    "parentEntity": widget.entity.name,
    "parentId": parentId,
    "mode": row == null ? "create" : "edit"
  },
);

  /*
print("=== DEBUG CHILD POPUP ===");
print("Entidad hija: ${childEntity.name}");
print("FK: $fk");
print("ParentId: $parentId");
print("InitialData: $initialData");*/
  // 4. Campos visibles
final visibleFields = childEntity.fields
    .where((f) => f.name != fk)
    .map((f) => f.name)
    .toList();
/*print("VisibleFields: $visibleFields");
print("==========================");*/

  if (!mounted) return;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: SizedBox(
          width: 600,
          height: 500,
          child: DynamicFormView(
            api: widget.api,
            entity: childEntity,
            initialData: initialData,
            visibleFields: visibleFields,
            onClose: () async {
              Navigator.of(context).pop();
              setState(() {});
            },
            onRequestClose: () async {
              Navigator.of(context).pop();
              setState(() {});
              return true;
            },
          ),
        ),
      );
    },
  );
}
    }