import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  final dateFormat = DateFormat('dd/MM/yyyy', 'es_CR');

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
        .map((c) => TextEditingController(text: _displayValue(c.value)))
        .toList();

    value2Controllers = conditions
        .map((c) => c.value2 != null
            ? TextEditingController(text: _displayValue(c.value2))
            : null)
        .toList();

    // Normalizar operadores inválidos
    final validValues = operators.map((o) => o.value).toSet();
    for (final c in conditions) {
      if (!validValues.contains(c.operator)) {
        c.operator = operators.first.value;
      }
    }

    Future.delayed(Duration.zero, () {
      if (_firstFocus.canRequestFocus) _firstFocus.requestFocus();
    });
  }

  // Convierte ISO → dd/MM/yyyy para mostrar
  String _displayValue(String? raw) {
    if (raw == null || raw.isEmpty) return "";
    if (widget.fieldType != "date") return raw;

    try {
      final dt = DateTime.tryParse(raw);
      if (dt == null) return raw;
      return dateFormat.format(dt);
    } catch (_) {
      return raw;
    }
  }

  // Convierte dd/MM/yyyy → yyyy-MM-dd para guardar
  String _normalizeDate(String input) {
    if (input.isEmpty) return "";
    try {
      final dt = dateFormat.parseStrict(input);
      return dt.toIso8601String().split("T").first;
    } catch (_) {
      return input;
    }
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
            child: _buildValueEditor(index),
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

  Widget _buildValueEditor(int index) {
    final cond = conditions[index];

    if (widget.fieldType == "date") {
      if (cond.operator == "between") {
        return _buildBetweenDatePicker(index);
      }
      return _buildSingleDatePicker(index);
    }

    // Editor normal (string, number, bool)
    return TextField(
      controller: controllers[index],
      focusNode: index == 0 ? _firstFocus : null,
      style: const TextStyle(fontSize: 13),
      decoration: const InputDecoration(
        hintText: "Valor",
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: OutlineInputBorder(),
      ),
      onChanged: (v) => cond.value = v,
    );
  }

  Widget _buildSingleDatePicker(int index) {
    final cond = conditions[index];
    final controller = controllers[index];

    return InkWell(
      onTap: () async {
        final initial = DateTime.tryParse(cond.value ?? "") ?? DateTime.now();

        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
          locale: const Locale('es', 'CR'),
        );

        if (picked != null) {
          cond.value = picked.toIso8601String().split("T").first;
          controller.text = dateFormat.format(picked);
          setState(() {});
        }
      },
      child: IgnorePointer(
        child: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Seleccione fecha",
            isDense: true,
            border: OutlineInputBorder(),
          ),
          style: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildBetweenDatePicker(int index) {
    final cond = conditions[index];
    final controller1 = controllers[index];
    final controller2 = value2Controllers[index] ??
        (value2Controllers[index] = TextEditingController());

    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () async {
              final initial =
                  DateTime.tryParse(cond.value ?? "") ?? DateTime.now();

              final picked = await showDatePicker(
                context: context,
                initialDate: initial,
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
                locale: const Locale('es', 'CR'),
              );

              if (picked != null) {
                cond.value = picked.toIso8601String().split("T").first;
                controller1.text = dateFormat.format(picked);
                setState(() {});
              }
            },
            child: IgnorePointer(
              child: TextField(
                controller: controller1,
                decoration: const InputDecoration(
                  hintText: "Desde",
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: InkWell(
            onTap: () async {
              final initial =
                  DateTime.tryParse(cond.value2 ?? "") ?? DateTime.now();

              final picked = await showDatePicker(
                context: context,
                initialDate: initial,
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
                locale: const Locale('es', 'CR'),
              );

              if (picked != null) {
                cond.value2 = picked.toIso8601String().split("T").first;
                controller2.text = dateFormat.format(picked);
                setState(() {});
              }
            },
            child: IgnorePointer(
              child: TextField(
                controller: controller2,
                decoration: const InputDecoration(
                  hintText: "Hasta",
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _applyFilters() {
    for (final c in conditions) {
      final op = c.operator;

      if (widget.fieldType == "date") {
        if (op == "between") {
          if (c.value == null || c.value!.isEmpty || c.value2 == null || c.value2!.isEmpty) {
            _showError("Debe seleccionar ambas fechas.");
            return;
          }
        } else {
          if (c.value == null || c.value!.isEmpty) {
            _showError("Debe seleccionar una fecha.");
            return;
          }
        }
      }
    }

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
  }
}