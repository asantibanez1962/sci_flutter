class FilterOperator {
  final String label;
  final String value;

  const FilterOperator(this.label, this.value);
}

class FilterOperators {
  static const text = [
    FilterOperator("Contiene", "contains"),
    FilterOperator("No contiene", "notcontains"),
    FilterOperator("Empieza con", "startswith"),
    FilterOperator("Termina con", "endswith"),
    FilterOperator("Igual a", "="),
    FilterOperator("Distinto de", "!="),
  ];

  static const number = [
    FilterOperator("=", "="),
    FilterOperator("!=", "!="),
    FilterOperator(">", ">"),
    FilterOperator("<", "<"),
    FilterOperator(">=", ">="),
    FilterOperator("<=", "<="),
    FilterOperator("Entre", "between"),
  ];

  static const date = [
    FilterOperator("Antes de", "before"),
    FilterOperator("Después de", "after"),
    FilterOperator("Entre", "between"),
  ];

  static List<FilterOperator> boolean = [
  FilterOperator("Es igual a", "="),
  FilterOperator("Es diferente de", "!="),
  
];
}