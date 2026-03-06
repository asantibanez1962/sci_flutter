//import 'dart:convert';

class FormMetadata {
  final String entity;
  final String mode; // "simple" | "master"
  final List<String> headerFields;
  final List<FormTabMetadata> tabs;

  FormMetadata({
    required this.entity,
    required this.mode,
    required this.headerFields,
    required this.tabs,
  });

  factory FormMetadata.fromJson(Map<String, dynamic> json) {
    return FormMetadata(
      entity: json['entity'],
      mode: json['mode'],
      headerFields: json['headerFields'] != null
          ? List<String>.from(json['headerFields'])
          : <String>[],
      tabs: json['tabs'] != null
          ? (json['tabs'] as List)
              .map((t) => FormTabMetadata.fromJson(t))
              .toList()
          : <FormTabMetadata>[],
    );
  }
}

class FormTabMetadata {
  final String key;
  final String title;
  final String type; // "form" | "list" | "grid"
  final List<String> fields;
  final List<String> columns;
  final RelationMetadata? relation;

  FormTabMetadata({
    required this.key,
    required this.title,
    required this.type,
    required this.fields,
    required this.columns,
    this.relation,
  });

 factory FormTabMetadata.fromJson(Map<String, dynamic> json) {
  return FormTabMetadata(
    key: json['key'] ?? "",
    title: json['title'] ?? "",
    type: json['type'] ?? "",
    fields: json['fields'] != null
        ? List<String>.from(json['fields'])
        : <String>[],
    columns: json['columns'] != null
        ? List<String>.from(json['columns'])
        : <String>[],
    relation: json['relation'] != null &&
              json['relation']['relatedEntity'] != null &&
              json['relation']['foreignKey'] != null
        ? RelationMetadata.fromJson(json['relation'])
        : null,
  );
}
}

class RelationMetadata {
  final String fieldName;
  final String relatedEntity;
  final String foreignKey;

  RelationMetadata({
    required this.fieldName,
    required this.relatedEntity,
    required this.foreignKey,
  });

  factory RelationMetadata.fromJson(Map<String, dynamic> json) {
    return RelationMetadata(
      fieldName: json['fieldName'] ?? "",
      relatedEntity: json['relatedEntity'] ?? "",
      foreignKey: json['foreignKey'] ?? "",
    );
  }
}