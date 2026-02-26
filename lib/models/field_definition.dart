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
  final int? minLength;
  final int? maxLength;
  final double? minValue;
  final double? maxValue;
  final String? regex;


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
    this.minLength,
    this.maxLength,
    this.minValue,
    this.maxValue,
    this.regex,

    });

  factory FieldDefinition.fromJson(Map<String, dynamic> json) {
    // Opciones (para dropdowns simples)
    //print(json);
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

      name: json['name'] ?? json['field'] ?? "",

      label: json['label'] ?? json['name'] ?? "",
       dataType: normalizeType(
        json['dataType'] ?? json['type'] ?? "string"
      ),

      isRequired: json['isRequired'] ?? false,
      isAutocomplete: json['isAutocomplete'] ?? false,
      options: parsedOptions,

      lookupEntity: json['lookupEntity'],
      lookupLabelField: json['lookupLabelField'],
      lookupDisplayFields: json['lookupDisplayFields'] != null
        ? List<String>.from(json['lookupDisplayFields'])
        : null,
       minLength: json['minLength'],
       maxLength: json['maxLength'],
       minValue: json['minValue'] != null ? (json['minValue'] as num).toDouble() : null,
       maxValue: json['maxValue'] != null ? (json['maxValue'] as num).toDouble() : null,
       regex: json['regex'],
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
String normalizeType(String t) {
  t = t.toLowerCase();

  if (t.contains("char") || t.contains("text")) return "string";

  if (t.contains("int")) return "number";
  if (t.contains("decimal") || t.contains("numeric") || t.contains("float"))
    return "number";

  if (t.contains("bit") || t == "bool" || t == "boolean")
    return "bool";

  if (t.contains("date") || t.contains("time"))
    return "date";

  return "string";
}