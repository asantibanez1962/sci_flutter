import 'package:flutter/material.dart';
import '../../models/master_data/form_section_master_data.dart';
import '../../models/master_data/form_detail_master_data.dart';
import '../../models/field_definition.dart';

class DynamicFormSectionRenderer extends StatelessWidget {
  final List<FormSectionMasterData> sections;
  final List<FieldDefinition> fields; // ← NUEVO  
  /// Función que construye un campo por nombre
  final Widget Function(String fieldName) buildField;

  const DynamicFormSectionRenderer({
    super.key,
    required this.sections,
    required this.fields,
    required this.buildField,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: sections.map(_buildSection).toList(),
    );
  }

  Widget _buildSection(FormSectionMasterData section) {
    final items = [...section.items]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));


    // ⭐⭐ VALIDACIÓN CRÍTICA PARA EVITAR CRASH ⭐⭐
    final availableFieldNames = fields.map((f) => f.name).toSet();

    List<Widget> rows = [];
    List<Widget> currentRow = [];
    int currentWidth = 0;

    for (final FormDetailMasterData item in items) {
      
      //debugPrint("render:${item.fieldName} ${item.style}");
      if (item.detailType != 'field' || item.fieldName == null) continue;

   // ⭐⭐ AQUÍ VA EL BLOQUE QUE PREGUNTASTE ⭐⭐
      if (!availableFieldNames.contains(item.fieldName)) {
       // debugPrint("Skipping unknown field: ${item.fieldName}");
        continue;
      }

      final width = item.width ?? 12;

      // Si no cabe en la fila actual → cerrar fila y abrir otra
      if (currentWidth + width > 12) {
        rows.add(_wrapRow(currentRow,currentWidth));
        currentRow = [];
        currentWidth = 0;
      }

      currentRow.add(
        Expanded(
          flex: width,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: buildField(item.fieldName!),
          ),
        ),
      );

      currentWidth += width;
    }

    // Última fila
    if (currentRow.isNotEmpty) {
      rows.add(_wrapRow(currentRow,currentWidth));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (section.name != null && section.name!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                section.name!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ...rows,
        ],
      ),
    );
  }

Widget _wrapRow(List<Widget> children, int usedWidth) {
  final remaining = 12 - usedWidth;

  if (remaining > 0) {
    children.add(Expanded(flex: remaining, child: SizedBox.shrink()));
  }

  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: children,
  );
}
}