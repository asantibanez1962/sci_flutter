import '../models/filter_condition.dart';

class ColumnFilter {
  final String field;
  final String logic;
  final List<FilterCondition> conditions;

  ColumnFilter({
    required this.field,
    this.logic = "and",
    required this.conditions,
  });

  Map<String, dynamic> toJson() {
    return {
      "field": field,
      "logic": logic,
      "conditions": conditions.map((c) => c.toJson()).toList(),
    };
  }
}
