class FilterCondition {
  String operator;
  dynamic value;
  dynamic value2;

  FilterCondition({
    required this.operator,
    this.value,
    this.value2,
  });

  Map<String, dynamic> toJson() {
    return {
      "operator": operator,
      "value": value,
      "value2": value2,
    };
  }
}