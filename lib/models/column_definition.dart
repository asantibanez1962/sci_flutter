class ColumnDefinition {
  final String field;
  final String label;
  bool visible;

  ColumnDefinition({
    required this.field,
    required this.label,
    this.visible = true,
  });

  // Para persistencia
  Map<String, dynamic> toJson() => {
        "field": field,
        "label": label,
        "visible": visible,
      };

  static ColumnDefinition fromJson(Map<String, dynamic> json) {
    return ColumnDefinition(
      field: json["field"],
      label: json["label"],
      visible: json["visible"] ?? true,
    );
  }
}