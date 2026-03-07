class LockStatus {
  final bool locked;
  final String? lockedBy;
  final DateTime? lockedAt;
  final String? sessionId;

  LockStatus({
    required this.locked,
    this.lockedBy,
    this.lockedAt,
    this.sessionId,
  });

  factory LockStatus.fromJson(Map<String, dynamic> json) {
    return LockStatus(
      locked: json["locked"] ?? false,
      lockedBy: json["lockedBy"],
      lockedAt: json["lockedAt"] != null
          ? DateTime.parse(json["lockedAt"])
          : null,
      sessionId: json["sessionId"],
    );
  }
}