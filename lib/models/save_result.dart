import 'dart:convert';
class SaveResult {
  final bool success;
  final bool conflict;
  final int? id;
  final String? message;
  final String? rowVersion;
  final String? currentRowVersion;
  final Map<String, dynamic>? data;

  SaveResult({
    required this.success,
    required this.conflict,
    this.id,
    this.message,
    this.rowVersion,
    this.currentRowVersion,
    this.data,
  });

  factory SaveResult.fromJson(Map<String, dynamic> json) {
    return SaveResult(
      success: json["success"] ?? false,
      conflict: json["conflict"] ?? false,
      id: json["id"] is int ? json["id"] : (json["id"] != null ? int.tryParse(json["id"].toString()) : null),
      message: json["message"],
      rowVersion: json["rowVersion"],
      currentRowVersion: json["currentRowVersion"],
      data: json["data"] is Map<String, dynamic> ? Map<String, dynamic>.from(json["data"]) : (json["data"] != null ? Map<String, dynamic>.from(jsonDecode(json["data"].toString())) : null),
    );
  }
}