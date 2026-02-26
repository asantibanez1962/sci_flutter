import 'package:flutter/material.dart';
import '../filters/column_filter.dart';
import '../models/filter_condition.dart';
import '../models/filter_operator.dart';

class FilterDialog extends StatefulWidget {
  final String field;
  final String fieldType;
  final ColumnFilter? filter;

  const FilterDialog({
    super.key,
    required this.field,
    required this.fieldType,
    this.filter,
  });

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  List<FilterCondition> conditions = [];
  List<TextEditingController> controllers = [];
  late List<FilterOperator> operators;

  String logic = "AND";
  final FocusNode _firstFocus = FocusNode();

  @override
  void initState() {
    super.initState();

    switch (widget.fieldType) {
      case "string":
        operators = FilterOperators.text;
        break;
      case "number":
        operators = FilterOperators.number;
        break;
      case "date":
        operators = FilterOperators.date;
        break;
      case "bool":
        operators = FilterOperators.boolean;
        break;
      default:
        operators = FilterOperators.text;
    }

    if (widget.filter != null) {
      logic = widget.filter!.logic;
      conditions = widget.filter!.conditions
          .map((c) => FilterCondition(
                operator: c.operator,
                value: c.value,
                value2: c.value2,
              ))
          .toList();
    } else {
      conditions = [
        FilterCondition(
          operator: widget.fieldType == "string" ? "contains" : "=",
          value: "",
        )
      ];
    }

    controllers = conditions
        .map((c) => TextEditingController(text: c.value?.toString() ?? ""))
        .toList();

    // ⭐ Foco automático en el primer campo
    Future.delayed(Duration.zero, () {
      if (_firstFocus.canRequestFocus) _firstFocus.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        "Filtros para ${widget.field}",
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),

      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ⭐ AND / OR compacto
            Row(
              children: [
                const Text("Combinar:", style: TextStyle(fontSize: 13)),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: logic,
                  isDense: true,
                  style: const TextStyle(fontSize: 13),
                  items: const [
                    DropdownMenuItem(
                      value: "AND",
                      child: Text("AND (todas)", style: TextStyle(fontSize: 13)),
                    ),
                    DropdownMenuItem(
                      value: "OR",
                      child: Text("OR (cualquiera)", style: TextStyle(fontSize: 13)),
                    ),
                  ],
                  onChanged: (v) => setState(() => logic = v!),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ⭐ Condiciones
            for (int i = 0; i < conditions.length; i++)
              _buildConditionRow(i),

            const SizedBox(height: 8),

            // ⭐ Botón agregar condición compacto
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text("Agregar condición", style: TextStyle(fontSize: 13)),
              onPressed: () {
                setState(() {
                  conditions.add(
                    FilterCondition(
                      operator: widget.fieldType == "string" ? "contains" : "=",
                      value: "",
                    ),
                  );
                  controllers.add(TextEditingController());
                });
              },
            )
          ],
        ),
      ),

      actionsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancelar", style: TextStyle(fontSize: 13)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(
              context,
              ColumnFilter(
                field: widget.field,
                logic: logic,
                conditions: conditions,
              ),
            );
          },
          child: const Text("Aplicar", style: TextStyle(fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildConditionRow(int index) {
    final cond = conditions[index];
    final controller = controllers[index];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // ⭐ Operador compacto
          Expanded(
            flex: 2,
            child: DropdownButton<String>(
              value: cond.operator,
              isExpanded: true,
              isDense: true,
              style: const TextStyle(fontSize: 13),
              items: operators
                  .map((op) => DropdownMenuItem(
                        value: op.value,
                        child: Text(op.label, style: const TextStyle(fontSize: 13)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => cond.operator = v!),
            ),
          ),

          const SizedBox(width: 6),

          // ⭐ Valor compacto
          Expanded(
            flex: 3,
            child: TextField(
              controller: controller,
              focusNode: index == 0 ? _firstFocus : null,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                hintText: "Valor",
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => cond.value = v,
            ),
          ),

          const SizedBox(width: 6),

          // ⭐ Eliminar compacto
          IconButton(
            icon: const Icon(Icons.delete, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              setState(() {
                conditions.removeAt(index);
                controllers.removeAt(index);
              });
            },
          ),
        ],
      ),
    );
  }
}