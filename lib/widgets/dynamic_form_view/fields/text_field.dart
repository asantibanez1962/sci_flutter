import 'package:flutter/material.dart';

class TextFieldWidget extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool modified;
  final String? errorText;
  final ValueChanged<String> onChanged;

  const TextFieldWidget({
    super.key,
    required this.label,
    required this.controller,
    required this.modified,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(fontSize: 13), // ⭐ Texto compacto
      decoration: InputDecoration(
        isDense: true, // ⭐ Reduce altura del TextField
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13), // ⭐ Label compacto
        errorText: errorText,
        errorStyle: const TextStyle(fontSize: 11), // ⭐ Error compacto

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 8,
        ), // ⭐ Reduce padding interno

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
        ),

        fillColor: modified ? Colors.orange.shade100 : null,
        filled: modified,

        prefixIcon: modified
            ? const Icon(
                Icons.warning_amber,
                color: Colors.orange,
                size: 18, // ⭐ Ícono compacto
              )
            : null,
        prefixIconConstraints: const BoxConstraints(
          minWidth: 32,
          minHeight: 32,
        ), // ⭐ Evita que el ícono agrande el campo
      ),
      onChanged: onChanged,
    );
  }
}