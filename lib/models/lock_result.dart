class LockResult {
  final bool success;
  final bool conflict;
  final String? message;
  final String? lockedBy;
  final DateTime? lockedAt;

  LockResult({
    required this.success,
    required this.conflict,
    this.message,
    this.lockedBy,
    this.lockedAt,
  });

  factory LockResult.fromJson(Map<String, dynamic> json) {
    return LockResult(
      success: json['success'] ?? false,
      conflict: json['conflict'] ?? false,
      message: json['message'],
      lockedBy: json['lockedBy'],
      lockedAt: json['lockedAt'] != null
          ? DateTime.parse(json['lockedAt'])
          : null,
    );
  }
}