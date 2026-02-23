class FieldDefinition {
  final int id;
  final String name;
  final String label;
  final String dataType;        // string, int, decimal, bool, datetime, lookup, relation
  final bool isRequired;
  final bool isAutocomplete;

  final List<Map<String, dynamic>>? options;

  FieldDefinition({
    required this.id,
    required this.name,
    required this.label,
    required this.dataType,
    required this.isRequired,
    required this.isAutocomplete,
    this.options,
  });

  factory FieldDefinition.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>>? parsedOptions;

    if (json['options'] != null && json['options'] is List) {
      parsedOptions = (json['options'] as List)
          .map((o) {
            if (o is Map<String, dynamic>) return o;
            if (o is String) return {"value": o, "label": o};
            if (o is num) return {"value": o, "label": o.toString()};
            return null;
          })
          .where((e) => e != null)
          .cast<Map<String, dynamic>>()
          .toList();
    }

    return FieldDefinition(
      id: json['id'] ?? 0,                         // 👈 DEFAULT SEGURO
      name: json['name'] ?? json['field'] ?? "",   // 👈 FALLBACK
      label: json['label'] ?? json['name'] ?? "",  // 👈 FALLBACK
      dataType: json['dataType'] ?? "string",      // 👈 DEFAULT
      isRequired: json['isRequired'] ?? false,     // 👈 DEFAULT
      isAutocomplete: json['isAutocomplete'] ?? false, // 👈 DEFAULT
      options: parsedOptions,
    );
  }

  String get fieldType {
    switch (dataType.toLowerCase()) {
      case "string":
      case "text":
        return "text";

      case "int":
      case "decimal":
      case "double":
      case "number":
        return "number";

      case "bool":
      case "boolean":
        return "bool";

      case "datetime":
      case "date":
        return "date";

      case "lookup":
        return "dropdown";

      case "relation":
        return isAutocomplete ? "autocomplete" : "dropdown";

      default:
        return "text";
    }
  }
}