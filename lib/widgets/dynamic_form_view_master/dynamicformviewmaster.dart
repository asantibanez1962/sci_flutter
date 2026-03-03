import 'package:flutter/material.dart';
import '../dynamic_form_view/dynamic_form_view.dart';
import '../dynamic_list_view/dynamic_list_view.dart';
import '../../api/api_client.dart';
import '../../models/entity_definition.dart';
import '../../models/form_metadata.dart';

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
        ...widget.metadata.tabs.map((t) => Tab(text: t.title)).toList(),
      ],
    );
  }

  /// ------------------------------------------------------------
  /// CONTENIDO DE CADA TAB
  /// ------------------------------------------------------------
  Widget _buildTabViews() {
    print("🟧 TabBarView children count = ${1 + widget.metadata.tabs.length}");
    print("🟧 TabBar tabs count = ${tabController.length}");

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
        }).toList(),
      ],
    );
  }

  /// ------------------------------------------------------------
  /// RENDERIZAR TAB SEGÚN TIPO
  /// ------------------------------------------------------------
  Widget _buildTabContent(FormTabMetadata tab) {
    if (tab.type == null) {
      print("❌ ERROR: tab.type es NULL para tab.key=${tab.key}");
    }

    print("🟥 DATA DEL MAESTRO:");
    widget.data.forEach((k, v) => print("   $k = $v"));

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
        print("🟦 Entrando a LIST TAB");
        print("   tab.key = ${tab.key}");
        print("   tab.type = ${tab.type}");
        print("   tab.fields = ${tab.fields}");
        print("   tab.columns = ${tab.columns}");
        print("   tab.relation = ${tab.relation}");
        print("   entityMap = ${widget.entityMap.keys.toList()}");
        print("   relatedEntity = ${tab.relation?.relatedEntity}");
        print("   foreignKey = ${tab.relation?.foreignKey}");
        print("   parentId (by FK) = ${widget.data[tab.relation?.foreignKey]}");

        // ENTIDAD HIJA CORRECTA: usa relatedEntity, NO fieldName
        final childEntity =
            widget.entityMap[tab.relation!.relatedEntity]!; // ← Contacto

final fk = tab.relation!.foreignKey; // "SocioNegocioId"

         //final fk = tab.relation!.foreignKey; // "SocioNegocioId"
        //final parentId = widget.data[widget.entity.primaryKey]; // "Id"
final pk = widget.entity.primaryKey; // "Id"
final parentId = widget.data[pk] 
    ?? widget.data[pk.toLowerCase()] 
    ?? widget.data[pk.toUpperCase()];

        print(
            "TAB: ${tab.key} → entidad hija: ${childEntity.name}, FK: $fk, parentId: $parentId");
        print("🟩 Construyendo DynamicListView con:");
        print("   entity = ${childEntity.name}");
        print("   parentFilter = { $pk: $parentId }");

        return DynamicListView(
          entity: childEntity,
          api: widget.api,
       //   parentFilter: {fk: parentId},
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

          onEdit: (row) => widget.onEditChild?.call(tab, row),
          onCreate: () => widget.onCreateChild?.call(tab),
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
}