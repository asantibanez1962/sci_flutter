import 'package:flutter/material.dart';

import 'dynamic_list_controller.dart';
import 'context_menu/dynamic_list_context_menu.dart';
import 'context_menu/dynamic_list_context_actions.dart';
import 'utils/cell_value_builder.dart';

class DynamicListTable extends StatelessWidget {
  final DynamicListController controller;
  final Function(Map<String, dynamic>) onEdit;

  const DynamicListTable({
    super.key,
    required this.controller,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    if (controller.rows.isEmpty) {
      return const Center(child: Text("No hay datos"));
    }

    return AnimatedOpacity(
      opacity: controller.tableVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          sortColumnIndex: controller.sortColumn != null
              ? controller.columns.indexWhere(
                  (c) => c.field == controller.sortColumn)
              : null,
          sortAscending: controller.sortAscending,
          columns: controller.columns
              .where((c) => c.visible)
              .map((col) {
            final field = col.field;
            final hasFilter = controller.columnFilters.containsKey(field);

            return DataColumn(
              label: GestureDetector(
                onSecondaryTapDown: (details) async {
                  final selected = await DynamicListContextMenu.show(
                    context: context,
                    position: details.globalPosition,
                    column: field,
                    hasFilter: hasFilter,
                    isDate: controller.inferType(field) == "date",
                  );

                  if (selected != null) {
                    await DynamicListContextActions.handle(
                      selected: selected,
                      column: field,
                      controller: controller,
                      context: context,
                    );
                  }
                },
                child: Row(
                  children: [
                    Text(
                      col.label,
                      style: TextStyle(
                        fontWeight:
                            hasFilter ? FontWeight.bold : FontWeight.normal,
                        color: hasFilter ? Colors.blue : Colors.black,
                      ),
                    ),
                    if (controller.sortColumn == field)
                      Icon(
                        controller.sortAscending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 16,
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
          rows: controller.rows.map((row) {
            return DataRow(
              cells: controller.columns
                  .where((c) => c.visible)
                  .map((col) {
                final value = row[col.field];

                // ⭐ Lookup dinámico
                if (controller.lookupMaps.containsKey(col.field)) {
                  final map = controller.lookupMaps[col.field]!;
                  final label = map[value] ?? value.toString();

                  return DataCell(
                    Text(label),
                    onTap: () => onEdit(Map<String, dynamic>.from(row)),
                  );
                }

                // ⭐ Valor normal
                return DataCell(
                  buildCellValue(value),
                  onTap: () => onEdit(Map<String, dynamic>.from(row)),
                );
              }).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }
}