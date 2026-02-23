import 'package:flutter/material.dart';

Widget buildCellValue(dynamic value) {
  if (value is bool) {
    return Icon(
      value ? Icons.check_circle : Icons.cancel,
      color: value ? Colors.green : Colors.red,
    );
  }
  return Text(value?.toString() ?? "");
}