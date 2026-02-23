import 'dart:convert';
//import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;


class ColumnVisibilityApi {
  final String baseUrl;

  ColumnVisibilityApi({required this.baseUrl});

Future<List<Map<String, dynamic>>> getColumnVisibility(String entity) async {
  //debugPrint(">>> Entity usada en GET: ${entity}");
  final response = await http.get(Uri.parse('$baseUrl/api/column-visibility/$entity'));

  if (response.statusCode != 200) return [];

  return List<Map<String, dynamic>>.from(jsonDecode(response.body));
}

Future<void> saveColumnVisibility(String entity, List<Map<String, dynamic>> data) async {
 
  //final response = 
  await http.post(
    Uri.parse('$baseUrl/api/column-visibility/$entity'),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(data),
  );

  //debugPrint(">>> Respuesta backend: ${response.statusCode}");
  //debugPrint(">>> Body backend: ${response.body}");
}

}