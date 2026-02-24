class FieldDefinition {
  final int id;
  final String name;
  final String label;
  final String dataType;
  final bool isRequired;
  final bool isAutocomplete;

  final List<Map<String, dynamic>>? options;

  // ⭐ Lookup dinámico
  final String? lookupEntity;
  final String? lookupLabelField;
  List<String>? lookupDisplayFields; // ej: ["Nombre", "Identidad"]
  

  FieldDefinition({
    required this.id,
    required this.name,
    required this.label,
    required this.dataType,
    required this.isRequired,
    required this.isAutocomplete,
    this.options,
    this.lookupEntity,
    this.lookupLabelField,
    this.lookupDisplayFields,
    });

  factory FieldDefinition.fromJson(Map<String, dynamic> json) {
    // Opciones (para dropdowns simples)
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
      id: json['id'] ?? 0,

      // 👇 AQUÍ ESTÁ LA CLAVE
      name: json['name'] ?? json['field'] ?? "",

      label: json['label'] ?? json['name'] ?? "",
      dataType: json['dataType'] ?? "string",
      isRequired: json['isRequired'] ?? false,
      isAutocomplete: json['isAutocomplete'] ?? false,
      options: parsedOptions,

      lookupEntity: json['lookupEntity'],
      lookupLabelField: json['lookupLabelField'],
      lookupDisplayFields: json['lookupDisplayFields'] != null
        ? List<String>.from(json['lookupDisplayFields'])
        : null,
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