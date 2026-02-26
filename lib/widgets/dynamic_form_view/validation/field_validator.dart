import 'package:flutter/foundation.dart';

import '../../../models/field_definition.dart';

class FieldValidator {
  static String? validate(FieldDefinition field, dynamic value) {
    
    //debugPrint("Validando ${field.name}: value='$value' minLength=${field.minLength}");
    // 1. Required
    if (field.isRequired) {
      if (value == null || value.toString().trim().isEmpty) {
        return "Este campo es obligatorio";
      }
    }

    if (value == null) return null;

    final text = value.toString();

    // 2. Min length
    if (field.minLength != null && text.length < field.minLength!) {
      return "Debe tener al menos ${field.minLength} caracteres";
    }

    // 3. Max length
    if (field.maxLength != null && text.length > field.maxLength!) {
      return "Debe tener máximo ${field.maxLength} caracteres";
    }

    // 4. Min value
    if (field.minValue != null && value is num && value < field.minValue!) {
      return "El valor mínimo es ${field.minValue}";
    }

    // 5. Max value
    if (field.maxValue != null && value is num && value > field.maxValue!) {
      return "El valor máximo es ${field.maxValue}";
    }

    // 6. Regex
    if (field.regex != null) {
      final reg = RegExp(field.regex!);
      if (!reg.hasMatch(text)) {
        return "Formato inválido";
      }
    }

    return null;
  }
}