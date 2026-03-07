class SaveResult {
  final bool success;
  final bool conflict;
  final String? message;
  final String? rowVersion;
  final String? currentRowVersion;

  SaveResult({
    required this.success,
    required this.conflict,
    this.message,
    this.rowVersion,
    this.currentRowVersion,
  });

  factory SaveResult.fromJson(Map<String, dynamic> json) {
    return SaveResult(
      success: json["success"] ?? false,
      conflict: json["conflict"] ?? false,
      message: json["message"],
      rowVersion: json["rowVersion"],
      currentRowVersion: json["currentRowVersion"],
    );
  }
}