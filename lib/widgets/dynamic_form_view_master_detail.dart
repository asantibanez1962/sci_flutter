import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'dynamic_form_view/dynamic_form_view.dart';
import 'dynamic_list_view/dynamic_list_view.dart';
import '../../api/api_client.dart';
import '../../models/entity_definition.dart';
import '../../models/form_metadata.dart';
import 'form_editing_mixin.dart';
import '../models/lock_status.dart';
import '../../models/field_definition.dart';

/// =============================================================
/// MASTER-DETAIL CON LOCKING INTEGRADO
/// =============================================================
class DynamicFormViewMasterDetail extends StatefulWidget {
  final FormMetadata metadata;
  final Map<String, dynamic> data; // registro maestro
  final ApiClient api;
  final EntityDefinition entity;
  final Map<String, EntityDefinition> entityMap;
final Future<void> Function()? onClose;
final Future<bool> Function()? onRequestClose;

  const DynamicFormViewMasterDetail({
    super.key,
    required this.metadata,
    required this.data,
    required this.api,
    required this.entity,
    required this.entityMap,
     this.onClose,
    this.onRequestClose,

  });

  @override
  State<DynamicFormViewMasterDetail> createState() =>
      _DynamicFormViewMasterDetailState();
}

class _DynamicFormViewMasterDetailState
    extends State<DynamicFormViewMasterDetail>
    with
        FormEditingMixin<DynamicFormViewMasterDetail>,
        TickerProviderStateMixin {

  late TabController tabController;
  late final String sessionId;
  final GlobalKey<DynamicFormViewState> _masterFormKey =    GlobalKey<DynamicFormViewState>();
  @override
  void initState() {
    super.initState();
//print(">>> MASTERDETAIL: initState()");

    // Sesión única por pestaña
    sessionId = const Uuid().v4();

    // Tabs: General + tabs dinámicos
    tabController = TabController(
      length: 1 + widget.metadata.tabs.length,
      vsync: this,
    );

    // Cargar lock del maestro
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkExistingLock();
    });
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  // =============================================================
  // LOCKING — implementación requerida por el mixin
  // =============================================================

  @override
  String get entityName => widget.entity.name;

  @override
  int get recordId {
    final pk = widget.entity.primaryKey;
    return widget.data[pk] ??
        widget.data[pk.toLowerCase()] ??
        widget.data[pk.toUpperCase()];
  }

  @override
  Future<LockResult> acquireLock() async {
    final result = await widget.api.lockRecord(entityName, recordId, sessionId);

    return LockResult(
      success: result.success,
      conflict: result.conflict,
      lockedBy: result.lockedBy,
      lockedAt: result.lockedAt,
    );
  }

  @override
  Future<void> releaseLock() =>
      widget.api.releaseLock(entityName, recordId, sessionId);

  @override
  Future<void> refreshLock() =>
      widget.api.refreshLock(entityName, recordId, sessionId);

  @override
  Future<LockStatus> fetchLockStatus() =>
      widget.api.getLockStatus(entityName, recordId);

  @override
  Future<void> saveChanges() async {
    // Aquí luego integrás guardado maestro + detalles
   // print("💾 Guardando maestro (placeholder)");
  }

  // =============================================================
  // UI
  // =============================================================

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        buildLockBanner(), // ⭐ Banner del maestro

        _buildTabs(),

        Expanded(
          child: _buildTabViews(),
        ),
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

  Widget _buildMasterForm() {
    return DynamicFormView(
      api: widget.api,
      entity: widget.entity,
      initialData: widget.data,
      visibleFields: widget.metadata.headerFields,
      onClose: () async {
      //   print("FORMVIEW SIMPLE: onClose() recibido");

        await releaseLock();
     //    print("FORMVIEW SIMPLE: releaseLock() ejecutado desde onClose");
      },
      onRequestClose: () async {
     //    print("FORMVIEW SIMPLE: onRequestClose() recibido");

        await releaseLock();
     //   print("FORMVIEW SIMPLE: releaseLock() ejecutado desde onRequestClose");
        return true;
      },
    );
  }

  Widget _buildTabContent(FormTabMetadata tab) {
    switch (tab.type) {
      case "form":
        return DynamicFormView(
          api: widget.api,
          entity: widget.entity,
          initialData: widget.data,
          visibleFields: tab.fields,
          onClose: () async => await releaseLock(),
          onRequestClose: () async {
            await releaseLock();
            return true;
          },
        );

      case "list":
        final childEntity =
            widget.entityMap[tab.relation!.relatedEntity]!; // ← Contacto
            final fk = tab.relation!.foreignKey; // "SocioNegocioId"
            final pk = widget.entity.primaryKey; // "Id"
            final parentId = widget.data[pk] 
              ?? widget.data[pk.toLowerCase()] 
              ?? widget.data[pk.toUpperCase()];
                //  print(            "TAB: ${tab.key} → entidad hija: ${childEntity.name}, FK: $fk, parentId: $parentId");
              //   print("🟩 Construyendo DynamicListView con:");
              //   print("   entity = ${childEntity.name}");
              //    print("   parentFilter = { $pk: $parentId }");
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
          child: Text("Tipo desconocido: ${tab.type}"),
        );
    }
  }
  Future<void> _openChildPopup(FormTabMetadata tab, Map<String, dynamic>? row) async {
  final childEntity = widget.entityMap[tab.relation!.relatedEntity]!;
  final fk = tab.relation!.foreignKey;

  // 1. Cargar metadata del hijo
  final rawColumns = await widget.api.getColumns(childEntity.name);
  childEntity.fields =
      rawColumns.map((e) => FieldDefinition.fromJson(e)).toList();

  // 2. Preparar initialData
  final pk = widget.entity.primaryKey;
  final parentId = widget.data[pk]
      ?? widget.data[pk.toLowerCase()]
      ?? widget.data[pk.toUpperCase()];

  final initialData = row ?? { fk: parentId };

  // 3. Campos visibles (ocultamos FK solo visualmente)
  final visibleFields = childEntity.fields
      .where((f) => f.name != fk)
      .map((f) => f.name)
      .toList();

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

            // ⭐ Locking del hijo
            onClose: () async {
              Navigator.of(context).pop();
              setState(() {}); // refrescar lista
            },

            onRequestClose: () async {
              Navigator.of(context).pop();
              setState(() {}); // refrescar lista
              return true;
            },
          ),
        ),
      );
    },
  );
}

Future<void> _handleClose() async {
  //print("MASTERDETAIL: _handleClose() INICIADO");

  // 1) Primero: reenviar onRequestClose al formulario maestro
  final ok = await _forwardRequestCloseToMaster();
  if (!ok) {
  //  print("MASTERDETAIL: cierre cancelado por el formulario maestro");
    return;
  }

  // 2) Liberar lock del MasterDetail (si tuviera uno propio)
  if (hasLock) {
 //   print("MASTERDETAIL: tiene lock propio, llamando releaseLock()");
    await releaseLock();
 //   print("MASTERDETAIL: releaseLock() completado");
    hasLock = false;
  } else {
  //  print("MASTERDETAIL: NO tenía lock propio");
  }

  // 3) Cancelar timer
  if (lockRefreshTimer != null) {
   // print("MASTERDETAIL: cancelando lockRefreshTimer");
    lockRefreshTimer!.cancel();
  }

  // 4) Llamar onClose del MasterDetail (cierra la pestaña)
  if (widget.onClose != null) {
  //  print("MASTERDETAIL: llamando widget.onClose()");
    await widget.onClose!();
  //  print("MASTERDETAIL: widget.onClose() completado");
  } else {
 //   print("MASTERDETAIL: NO hay onClose definido");
  }

 // print("MASTERDETAIL: _handleClose() FINALIZADO");
}

Future<bool> _forwardRequestCloseToMaster() async {
 // print("MASTERDETAIL: reenviando onRequestClose al formulario maestro");

  final form = _masterFormKey.currentState;

  if (form == null) {
  //  print("MASTERDETAIL: NO hay estado del formulario maestro");
    return true;
  }

  final callback = form.widget.onRequestClose;

  if (callback == null) {
   // print("MASTERDETAIL: formulario maestro NO tiene onRequestClose");
    return true;
  }

  final ok = await callback();
 // print("MASTERDETAIL: resultado del cierre maestro: $ok");
  return ok;
}

}