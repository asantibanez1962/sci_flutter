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
          dataRowMinHeight: 32,
          dataRowMaxHeight: 36,
          headingRowHeight: 38,
          columnSpacing: 12,
          horizontalMargin: 8,

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
              label: MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => controller.state.setState(() {
                  controller.hoveredHeader = field;
                }),
                onExit: (_) => controller.state.setState(() {
                  controller.hoveredHeader = null;
                }),
                child: GestureDetector(
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 2, horizontal: 4),
                    decoration: BoxDecoration(
                      color: controller.hoveredHeader == field
                          ? Colors.blue.withValues(alpha: 0.06)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Row(
                      children: [
                        Text(
                          col.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: hasFilter
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: controller.hoveredHeader == field
                                ? Colors.blue
                                : (hasFilter ? Colors.blue : Colors.black),
                          ),
                        ),

                        if (controller.sortColumn == field)
                          Icon(
                            controller.sortAscending
                                ? Icons.arrow_drop_up
                                : Icons.arrow_drop_down,
                            size: 18,
                            color: Colors.blue,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),

          rows: controller.rows.asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;

            final isHovered = controller.hoveredRow == index;

            return DataRow(
              color: WidgetStateProperty.resolveWith((states) {
                return isHovered
                    ? Colors.blue.withValues(alpha: 0.08)
                    : null;
              }),
              cells: controller.columns
                  .where((c) => c.visible)
                  .map((col) {
                final value = row[col.field];

                return DataCell(
                  MouseRegion(
                    onEnter: (_) => controller.state.setState(() {
                      controller.hoveredRow = index;
                    }),
                    onExit: (_) => controller.state.setState(() {
                      controller.hoveredRow = null;
                    }),
                    child: DefaultTextStyle(
                      style: TextStyle(
                        fontSize: 12,
                        color: isHovered ? Colors.blue : Colors.black,
                        fontWeight:
                            isHovered ? FontWeight.w600 : FontWeight.normal,
                      ),
                  child: () {
                   //   debugPrint("CELL → field=${col.field}, lookup=${controller.lookupMaps.containsKey(col.field)}, value=$value");
                      return controller.lookupMaps.containsKey(col.field)
                          ? Text(
                              controller.lookupMaps[col.field]![value] ??
                                  value.toString(),
                            )
                          : buildCellValue(value);
                    }(),                   ),
                  ),
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