import 'package:flutter/material.dart';

Widget buildCellValue(dynamic value) {
 //
  if (value == null) return const Text("");

  // ✔ Booleanos con íconos
  if (value is bool) {
    return Icon(
      value ? Icons.check_circle : Icons.cancel,
      color: value ? Colors.green : Colors.red,
    );
  }

  // ✔ Detectar fecha en String (ISO o SQL)
  if (value is String && _looksLikeDate(value)) {
   // debugPrint("🔥 buildCellValue ejecutado 2 → $value");
    final normalized = value.replaceFirst("T", " ");
    final date = DateTime.tryParse(normalized);

    if (date != null) {
    //   debugPrint("🔥 buildCellValue ejecutado 3 → $value");
      final formatted = "${_two(date.day)}/${_two(date.month)}/${date.year}";
      return Text(formatted);
    }
  }

  // ✔ Detectar DateTime real
  if (value is DateTime) {
    final formatted = "${_two(value.day)}/${_two(value.month)}/${value.year}";
    return Text(formatted);
  }

  // ✔ Números
  if (value is num) {
    return Text(value.toString());
  }

  // ✔ Texto normal
  return Text(value.toString());
}

bool _looksLikeDate(String s) {
  final regex = RegExp(r'^\d{4}-\d{2}-\d{2}');
  return regex.hasMatch(s);
}


String _two(int n) => n.toString().padLeft(2, '0');