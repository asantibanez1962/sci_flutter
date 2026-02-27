class ColumnDefinition {
  final String field;
  final String label;
  final String fieldType; 
  bool visible;

  ColumnDefinition({
    required this.field,
    required this.label,
    required this.fieldType,
    this.visible = true,
  });

  Map<String, dynamic> toJson() => {
        "field": field,
        "label": label,
        "fieldType": fieldType, 
        "visible": visible,
      };

  static ColumnDefinition fromJson(Map<String, dynamic> json) {
    return ColumnDefinition(
      field: json["field"],
      label: json["label"],
      fieldType: json["fieldType"], 
      visible: json["visible"] ?? true,
    );
  }
}