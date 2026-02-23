import 'package:flutter/material.dart';
import '../../../filters/column_filter.dart';
import '../../../models/filter_condition.dart';
import '../dynamic_list_controller.dart';
import '../../filter_dialog.dart';

class DynamicListContextActions {
  static Future<void> handle({
    required String selected,
    required String column,
    required DynamicListController controller,
    required BuildContext context,
  }) async {
    switch (selected) {
      case "asc":
        controller.sortByColumn(column, ascending: true);
        break;

      case "desc":
        controller.sortByColumn(column, ascending: false);
        break;

      case "empty":
        controller.applyFilter(
          ColumnFilter(
            field: column,
            logic: "AND",
            conditions: [
              FilterCondition(operator: "isEmpty", value: ""),
            ],
          ),
        );
        break;

      case "notEmpty":
        controller.applyFilter(
          ColumnFilter(
            field: column,
            logic: "AND",
            conditions: [
              FilterCondition(operator: "isNotEmpty", value: ""),
            ],
          ),
        );
        break;

      case "equals":
        final value = await controller.promptValue("Igual a", column);
        if (value != null) {
          controller.applyFilter(
            ColumnFilter(
              field: column,
              logic: "AND",
              conditions: [
                FilterCondition(operator: "=", value: value),
              ],
            ),
          );
        }
        break;

      case "notEquals":
        final value = await controller.promptValue("Distinto de", column);
        if (value != null) {
          controller.applyFilter(
            ColumnFilter(
              field: column,
              logic: "AND",
              conditions: [
                FilterCondition(operator: "!=", value: value),
              ],
            ),
          );
        }
        break;

      case "filter":
        final result = await showDialog(
          context: context,
          builder: (_) => FilterDialog(
            field: column,
            fieldType: controller.inferType(column),
            filter: controller.columnFilters[column],
          ),
        );

        if (result != null) controller.applyFilter(result);
        break;

      case "clear":
        controller.clearFilter(column);
        break;

      case "clearAll":
        controller.clearAllFilters();
        break;

      case "today":
        final now = DateTime.now();
        controller.applyFilter(
          ColumnFilter(
            field: column,
            logic: "AND",
            conditions: [
              FilterCondition(
                operator: "between",
                value: now.toIso8601String(),
                value2: now.toIso8601String(),
              ),
            ],
          ),
        );
        break;

      case "yesterday":
        final y = DateTime.now().subtract(const Duration(days: 1));
        controller.applyFilter(
          ColumnFilter(
            field: column,
            logic: "AND",
            conditions: [
              FilterCondition(
                operator: "between",
                value: y.toIso8601String(),
                value2: y.toIso8601String(),
              ),
            ],
          ),
        );
        break;

      case "thisWeek":
        final now = DateTime.now();
        final start = now.subtract(Duration(days: now.weekday - 1));
        final end = start.add(const Duration(days: 6));
        controller.applyFilter(
          ColumnFilter(
            field: column,
            logic: "AND",
            conditions: [
              FilterCondition(
                operator: "between",
                value: start.toIso8601String(),
                value2: end.toIso8601String(),
              ),
            ],
          ),
        );
        break;

      case "thisMonth":
        final now = DateTime.now();
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0);
        controller.applyFilter(
          ColumnFilter(
            field: column,
            logic: "AND",
            conditions: [
              FilterCondition(
                operator: "between",
                value: start.toIso8601String(),
                value2: end.toIso8601String(),
              ),
            ],
          ),
        );
        break;

      case "hideColumn":
        final col =
            controller.columns.firstWhere((c) => c.field == column);
        col.visible = false;
        controller.state.setState(() {});
        break;
    }
  }
}