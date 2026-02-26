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
  List<TextEditingController?> value2Controllers = [];
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

    value2Controllers = conditions
        .map((c) => c.value2 != null
            ? TextEditingController(text: c.value2.toString())
            : null)
        .toList();

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
            for (int i = 0; i < conditions.length; i++) _buildConditionRow(i),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text("Agregar condición",
                  style: TextStyle(fontSize: 13)),
              onPressed: () {
                setState(() {
                  conditions.add(
                    FilterCondition(
                      operator:
                          widget.fieldType == "string" ? "contains" : "=",
                      value: "",
                    ),
                  );
                  controllers.add(TextEditingController());
                  value2Controllers.add(null);
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
          onPressed: _applyFilters,
          child: const Text("Aplicar", style: TextStyle(fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildConditionRow(int index) {
    final cond = conditions[index];
    final controller = controllers[index];
    final value2Controller = value2Controllers[index];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
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
                        child: Text(op.label,
                            style: const TextStyle(fontSize: 13)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => cond.operator = v!),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 3,
            child: cond.operator == "between"
                ? Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          focusNode: index == 0 ? _firstFocus : null,
                          style: const TextStyle(fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: "Desde",
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (v) => cond.value = v,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: value2Controller ??
                              (value2Controllers[index] =
                                  TextEditingController(
                                      text: cond.value2?.toString() ?? "")),
                          style: const TextStyle(fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: "Hasta",
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (v) => cond.value2 = v,
                        ),
                      ),
                    ],
                  )
                : TextField(
                    controller: controller,
                    focusNode: index == 0 ? _firstFocus : null,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: "Valor",
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => cond.value = v,
                  ),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.delete, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              setState(() {
                conditions.removeAt(index);
                controllers.removeAt(index);
                value2Controllers.removeAt(index);
              });
            },
          ),
        ],
      ),
    );
  }

void _applyFilters() {
  for (final c in conditions) {
    final op = c.operator;
    final v1 = c.value?.toString().trim() ?? "";
    final v2 = c.value2?.toString().trim() ?? "";

    // -----------------------------
    // VALIDACIÓN PARA BETWEEN
    // -----------------------------
    if (op == "between") {
      if (v1.isEmpty || v2.isEmpty) {
        _showError("Debe ingresar ambos valores para 'Entre'.");
        return;
      }

      if (widget.fieldType == "number") {
        if (num.tryParse(v1) == null || num.tryParse(v2) == null) {
          _showError("Los valores deben ser numéricos.");
          return;
        }
      }

      if (widget.fieldType == "date") {
        if (DateTime.tryParse(v1) == null || DateTime.tryParse(v2) == null) {
          _showError("Las fechas deben tener un formato válido (YYYY-MM-DD).");
          return;
        }
      }

      continue; // BETWEEN validado
    }

    // -----------------------------
    // VALIDACIÓN PARA OPERADORES NORMALES
    // -----------------------------
    if (v1.isEmpty) {
      _showError("Debe ingresar un valor para el filtro.");
      return;
    }

    if (widget.fieldType == "number") {
      if (num.tryParse(v1) == null) {
        _showError("El valor debe ser numérico.");
        return;
      }
    }

    if (widget.fieldType == "date") {
      if (DateTime.tryParse(v1) == null) {
        _showError("La fecha debe tener un formato válido (YYYY-MM-DD).");
        return;
      }
    }

    if (widget.fieldType == "bool") {
      if (v1.toLowerCase() != "true" && v1.toLowerCase() != "false") {
        _showError("El valor debe ser true o false.");
        return;
      }
    }
  }

  // Si todo está bien → aplicar filtros
  Navigator.pop(
    context,
    ColumnFilter(
      field: widget.field,
      logic: logic,
      conditions: conditions,
    ),
  );
}

void _showError(String msg) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg)),
  );
}}