import 'package:flutter/material.dart';

class TextFieldWidget extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool modified;
  final ValueChanged<String> onChanged;

  const TextFieldWidget({
    super.key,
    required this.label,
    required this.controller,
    required this.modified,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        fillColor: modified ? Colors.orange.shade100 : null,
        filled: modified,
        prefixIcon: modified
            ? const Icon(Icons.warning_amber, color: Colors.orange)
            : null,
      ),
      onChanged: onChanged,
    );
  }
}