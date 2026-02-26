import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/entity_definition.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  final String baseUrl;

  ApiClient({required this.baseUrl});

  Future<List<EntityDefinition>> getEntities() async {
    final res = await http.get(Uri.parse('$baseUrl/metadata/entities'));
    if (res.statusCode != 200) {
      throw Exception('Error al obtener entidades');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => EntityDefinition.fromJson(e)).toList();
  }

Future<EntityDefinition> getEntityMetadata(String entityName) async {
  final url = Uri.parse('$baseUrl/metadata/entity/$entityName');
  final response = await http.get(url);
  //debugPrint("RAW DATA RESPONSE: ${response.body}");
  if (response.statusCode != 200) {
    throw Exception('Error al obtener metadata de entidad: ${response.body}');
  }

  final jsonData = jsonDecode(response.body);
  return EntityDefinition.fromJson(jsonData);
}


  Future<EntityDefinition> getEntity(String name) async {
    final res = await http.get(Uri.parse('$baseUrl/metadata/entities/$name'));
    if (res.statusCode != 200) {
      throw Exception('Error al obtener entidad $name');
    }
    return EntityDefinition.fromJson(jsonDecode(res.body));
  }

  Future<List<Map<String, dynamic>>> getData(String entity) async {
   final url = Uri.parse('$baseUrl/data/$entity');
    final res = await http.get(url);

    //debugPrint("RAW DATA RESPONSE: ${res.body}");

    if (res.statusCode != 200) {
      throw Exception('Error al obtener datos de $entity');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  /// NUEVO: lista con soporte de filtros
  Future<List<Map<String, dynamic>>> getList(
    String entity, {
    List<Map<String, dynamic>>? filters,
  }) async {
    // Si no hay filtros, usamos el endpoint existente
    if (filters == null || filters.isEmpty) {
      return getData(entity);
    }

    // Si hay filtros, llamamos a un endpoint de búsqueda
    // Contrato sugerido: POST /data/{entity}/filter
    final url = Uri.parse('$baseUrl/data/$entity/filter');
    
    debugPrint("URL llamada: $url");
    debugPrint("Body enviado: ${jsonEncode({"filters": filters})}");

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "filters": filters,
      }),
    );

    debugPrint("RAW LIST RESPONSE: ${res.body}");


    if (res.statusCode != 200) {
      throw Exception('Error al obtener datos filtrados de $entity: ${res.body}');
    }

    final list = jsonDecode(res.body) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }


Future<Map<String, dynamic>> saveData(
  String entity,
  Map<String, dynamic> data, {
  int? id,
}) async {
  final url = id == null
      ? '$baseUrl/data/$entity'
      : '$baseUrl/data/$entity/$id';

  debugPrint("➡️ saveData() INICIO");
  debugPrint("URL: $url");
  debugPrint("DATA: ${jsonEncode(data)}");

  final response = await (id == null
      ? http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(data),
        )
      : http.put(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(data),
        ));

  debugPrint("⬅️ saveData() RESPONSE STATUS: ${response.statusCode}");
  debugPrint("⬅️ saveData() RESPONSE BODY RAW: '${response.body}'");

  if (response.statusCode != 200) {
    throw Exception('Error al guardar datos: ${response.body}');
  }

  // 🔥 Manejo seguro del body
  if (response.body.isEmpty) {
    debugPrint("⚠️ BODY VACÍO, devolviendo success=true");
    return {"success": true};
  }

  try {
    final decoded = jsonDecode(response.body);

    debugPrint("📦 saveData() JSON DECODED: $decoded");

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    // Si devuelve un número, string, etc.
    return {"success": true, "data": decoded};
  } catch (e) {
    debugPrint("⚠️ JSON DECODE FALLÓ: $e");
    return {"success": true};
  }
}//savedata


  Future<Map<String, dynamic>> getById(String entity, dynamic id) async {
    final url = Uri.parse('$baseUrl/data/$entity/$id');

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception("Error al obtener $entity con ID $id");
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>?> getColumnVisibility(String entity) async {
  final url = Uri.parse('$baseUrl/column-visibility/$entity');

  final response = await http.get(url);

  if (response.statusCode == 200) {
    final list = jsonDecode(response.body) as List;
    return list.cast<Map<String, dynamic>>();
  }

  return null;
}

Future<List<Map<String, dynamic>>> getColumns(String entity) async {
  final response = await http.get(Uri.parse('$baseUrl/metadata/$entity/columns'));

  if (response.statusCode != 200) {
    throw Exception("Error al obtener columnas");
  }

  return List<Map<String, dynamic>>.from(jsonDecode(response.body));
}


Future<List<Map<String, dynamic>>> getLookupRows(
  String entity,
  List<String> displayFields,
) async {
  final url = Uri.parse("$baseUrl/lookup/$entity");

  final body = jsonEncode({"fields": displayFields});
  debugPrint(">>> SENDING BODY = $body");

  final res = await http.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: body,
  );

  debugPrint(">>> STATUS = ${res.statusCode}");
  debugPrint(">>> RAW BODY LENGTH = ${res.body.length}");
  debugPrint(">>> RAW BODY = '${res.body}'"); // notar comillas

  if (res.statusCode != 200) {
    debugPrint(">>> ERROR RESPONSE");
    return [];
  }

  if (res.body.isEmpty) {
    debugPrint(">>> EMPTY BODY");
    return [];
  }

  dynamic decoded;

  try {
    decoded = jsonDecode(res.body);
  } catch (e) {
    debugPrint(">>> JSON ERROR: $e");
    return [];
  }

  if (decoded is! List) {
    debugPrint(">>> NOT A LIST: $decoded");
    return [];
  }

  return List<Map<String, dynamic>>.from(decoded);
}

}