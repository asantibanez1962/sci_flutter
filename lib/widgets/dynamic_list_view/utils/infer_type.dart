String inferTypeFromRows(String field, List<Map<String, dynamic>> rows) {
  if (rows.isEmpty) return "string";

  final value = rows.first[field];

  if (value is int || value is double) return "number";
  if (value is bool) return "bool";
  if (value is DateTime) return "date";

  return "string";
}