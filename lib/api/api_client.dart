import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/entity_definition.dart';
import '../models/form_metadata.dart';
import '../../models/master_data/form_metadata_master_data.dart';
import '../models/lock_result.dart';
import '../models/lock_status.dart';
import '../models/save_result.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  final String baseUrl;
  final String userId = "dev-user"; // o "alfredo", o un GUID fijo

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
  /*debugPrint("RAW DATA RESPONSE: ${response.body}");
  if (response.statusCode != 200) {
    throw Exception('Error al obtener metadata de entidad: ${response.body}');
  }*/

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
  // ---------------------------------------------
  // 1) GET normal (sin filtros)
  // ---------------------------------------------
  if (filters == null || filters.isEmpty) {
    final url = Uri.parse('$baseUrl/data/$entity');

    final res = await http.get(url);
    //debugPrint("Respuesta backend (GET): ${res.body}");

    final List<dynamic> data = jsonDecode(res.body);

    // Normalizar claves y convertir LinkedMap → Map<String, dynamic>
    return data.map<Map<String, dynamic>>((row) {
      final map = Map<String, dynamic>.from(row as Map);

      return map.map((key, value) {
        final k = key.toString();
        final normalizedKey = k[0].toUpperCase() + k.substring(1);
        return MapEntry(normalizedKey, value);
      });
    }).toList();
  }

  // ---------------------------------------------
  // 2) POST /filter (con filtros)
  // ---------------------------------------------
  final url = Uri.parse('$baseUrl/data/$entity/filter');
   //debugPrint("URL llamada (GET): $url  $entity");

  //debugPrint("URL llamada (POST FILTER): $url");
  //debugPrint("Body enviado: ${jsonEncode({"filters": filters})}");

  final res = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({"filters": filters}),
  );

  //debugPrint("Respuesta backend (FILTER): ${res.body}");

  final List<dynamic> data = jsonDecode(res.body);

  // Normalizar claves y convertir LinkedMap → Map<String, dynamic>
  return data.map<Map<String, dynamic>>((row) {
    final map = Map<String, dynamic>.from(row as Map);

    return map.map((key, value) {
      final k = key.toString();
      final normalizedKey = k[0].toUpperCase() + k.substring(1);
      return MapEntry(normalizedKey, value);
    });
  }).toList();
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
 debugPrint(jsonEncode(data));

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

  //debugPrint("⬅️ saveData() RESPONSE STATUS: ${response.statusCode}");
  //debugPrint("⬅️ saveData() RESPONSE BODY RAW: '${response.body}'");

  if (response.statusCode != 200) {
    throw Exception('Error al guardar datos: ${response.body}');
  }

  // 🔥 Manejo seguro del body
  if (response.body.isEmpty) {
   // debugPrint("⚠️ BODY VACÍO, devolviendo success=true");
    return {"success": true};
  }

  try {
    final decoded = jsonDecode(response.body);

    //debugPrint("📦 saveData() JSON DECODED: $decoded");

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    // Si devuelve un número, string, etc.
    return {"success": true, "data": decoded};
  } catch (e) {
    //debugPrint("⚠️ JSON DECODE FALLÓ: $e");
    return {"success": true};
  }
}//savedata


Future<SaveResult> saveRecord(String entity, Map<String, dynamic> data, {int? id}) async {
  final raw = await saveData(entity, data, id: id);
  return SaveResult.fromJson(raw);
}

Future<Map<String, dynamic>> getById(String entity, dynamic id) async {
  final url = Uri.parse("$baseUrl/data/$entity/$id");
  final res = await http.get(url);

  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  }

  throw Exception("Error al cargar $entity/$id");
}

  Future<List<Map<String, dynamic>>?> getColumnVisibility(String entity) async {
  final url = Uri.parse('$baseUrl/column-visibility/$entity');
print("visibility:$url");
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
//print(response.body);
  return List<Map<String, dynamic>>.from(jsonDecode(response.body));
}


Future<List<Map<String, dynamic>>> getLookupRows(
  String entity,
  List<String> displayFields,
) async {
  final url = Uri.parse("$baseUrl/lookup/$entity");

  final body = jsonEncode({"fields": displayFields});
  //debugPrint(">>> SENDING BODY = $body");

  final res = await http.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: body,
  );

//  debugPrint(">>> STATUS = ${res.statusCode}");
//  debugPrint(">>> RAW BODY LENGTH = ${res.body.length}");
//  debugPrint(">>> RAW BODY = '${res.body}'"); // notar comillas

  if (res.statusCode != 200) {
  //  debugPrint(">>> ERROR RESPONSE");
    return [];
  }

  if (res.body.isEmpty) {
  //  debugPrint(">>> EMPTY BODY");
    return [];
  }

  dynamic decoded;

  try {
    decoded = jsonDecode(res.body);
  } catch (e) {
   // debugPrint(">>> JSON ERROR: $e");
    return [];
  }

  if (decoded is! List) {
  //  debugPrint(">>> NOT A LIST: $decoded");
    return [];
  }

  return List<Map<String, dynamic>>.from(decoded);
}

Future<FormMetadata> getFormMetadata(String entityName) async {
  //print("anterior metadata $entityName");
  final response = await http.get(
    Uri.parse('$baseUrl/metadata/form/$entityName'),
  );
  //debugPrint("📌 JSON metadata recibido para $entityName:");
  //debugPrint(response.body);   

  if (response.statusCode != 200) {
    throw Exception("Error loading form metadata for $entityName");
  }

  final jsonData = jsonDecode(response.body);
  return FormMetadata.fromJson(jsonData);
}

Future<FormMetadataMasterData> getFormMetadataMaster(String entityName) async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/forms/$entityName'),
  );
  //debugPrint("$baseUrl/api/forms/$entityName");
  //debugPrint("📌 JSON metadata nuevo para $entityName:");
  //debugPrint(response.body);   

  if (response.statusCode != 200) {
    throw Exception("Error loading master Form metadata for $entityName");
  }

  final jsonData = jsonDecode(response.body);
  //debugPrint("=== FORM RESPONSE ===");
 // debubPrint(const JsonEncoder.withIndent('  ').convert(response.data));
  //debugPrint(const JsonEncoder.withIndent('  ').convert(response.body));

  return FormMetadataMasterData.fromJson(jsonData);
}

Future<void> logUiEvent({
  required String eventType,
  String? entity,
  int? recordId,
  Map<String, dynamic>? details,
}) async {
  final url = Uri.parse("$baseUrl/ui-log");

  final body = {
    "eventType": eventType,
    "entity": entity,
    "recordId": recordId,
    "details": details,
    "userName": "pending" // luego integrás usuario real
  };

  await http.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(body),
  );
}

  // -----------------------------------------
  // ACQUIRE LOCK
  // -----------------------------------------
Future<LockResult> lockRecord(String entity, int? id, String sessionId) async {
  final url = Uri.parse('$baseUrl/api/lock/$entity/$id/acquire');
  //print(">>> URL: $url");
  //print(">>> LOCK REQUEST: entity=$entity id=$id userId=$userId sessionId=$sessionId");

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'userId': userId,
      'sessionId': sessionId,   // ⭐ NUEVO
    }),
  );

  if (response.body.isEmpty) {
    return LockResult(
      success: false,
      conflict: true,
      message: "Respuesta vacía del servidor",
      lockedBy: null,
      lockedAt: null,
    );
  }

  final json = jsonDecode(response.body);

  if (response.statusCode == 409) {
    return LockResult(
      success: false,
      conflict: true,
      message: json["message"],
      lockedBy: json["lockedBy"],
      lockedAt: json["lockedAt"] != null
          ? DateTime.parse(json["lockedAt"])
          : null,
    );
  }

  if (response.statusCode == 400) {
    return LockResult(
      success: false,
      conflict: false,
      message: json["message"],
      lockedBy: null,
      lockedAt: null,
    );
  }

  return LockResult(
    success: true,
    conflict: false,
    message: null,
    lockedBy: null,
    lockedAt: null,
  );
}
  // -----------------------------------------
  // REFRESH LOCK
  // -----------------------------------------
Future<bool> refreshLock(String entity, int? id, String sessionId) async {
  final url = Uri.parse('$baseUrl/api/lock/$entity/$id/refresh');
 // debugPrint("refresh:$url");
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'userId': userId,
      'sessionId': sessionId,   // ⭐ NUEVO
    }),
  );

  if (response.body.isEmpty) {
    debugPrint("⚠️ refreshLock(): respuesta vacía del servidor");
    return false;
  }

  final json = jsonDecode(response.body);

  if (response.statusCode == 409) {
    debugPrint("⚠️ refreshLock(): conflicto → ${json["message"]}");
    return false;
  }

  if (response.statusCode == 400) {
    debugPrint("⚠️ refreshLock(): error → ${json["message"]}");
    return false;
  }

  return true;
}

// -----------------------------------------
  // RELEASE LOCK
  // -----------------------------------------
Future<void> releaseLock(String entity, int? id, String sessionId) async {
  final url = Uri.parse('$baseUrl/api/lock/$entity/$id/release');
//print("🔥 RELEASE LOCK ejecutado desde dispose()");
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'userId': userId,
      'sessionId': sessionId,   // ⭐ NUEVO
    }),
  );

  if (response.statusCode != 200) {
    debugPrint("⚠️ releaseLock(): error → ${response.body}");
  }
}

Future<LockStatus> getLockStatus(String entity, int? id) async {
  final url = Uri.parse("$baseUrl/api/lock/$entity/$id/status");

  final response = await http.get(url);

  if (response.statusCode != 200) {
    throw Exception("Error al consultar estado del lock");
  }

  final data = jsonDecode(response.body);
  return LockStatus.fromJson(data);
}

}
