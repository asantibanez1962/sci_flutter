import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NumberFieldWidget extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool modified;
  final ValueChanged<double?> onChanged;

  const NumberFieldWidget({
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
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        fillColor: modified ? Colors.orange.shade100 : null,
        filled: modified,
        prefixIcon: modified
            ? const Icon(Icons.warning_amber, color: Colors.orange)
            : null,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
      ],
      onChanged: (v) {
        final parsed = double.tryParse(v.replaceAll(",", "."));
        onChanged(parsed);
      },
    );
  }
}