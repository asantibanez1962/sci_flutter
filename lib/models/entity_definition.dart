import 'field_definition.dart';

class EntityDefinition {
  final String name;
  final String displayName;
  final String primaryKey;
  List<FieldDefinition> fields;

  EntityDefinition({
    required this.name,
    required this.displayName,
    required this.primaryKey,
    required this.fields,
  });

  factory EntityDefinition.fromJson(Map<String, dynamic> json) {
   //  print("JSON EN EntityDefinition.fromJson:");
    //print(json);

    return EntityDefinition(
      name: json['name'],
      displayName: json['displayName'],
      primaryKey: json['primaryKey'],
      fields: (json['fields'] as List)
          .map((f) => FieldDefinition.fromJson(f))
          .toList(),
    );
  }
}