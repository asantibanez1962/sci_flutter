import 'package:flutter/material.dart';

class DateFieldWidget extends StatelessWidget {
  final String label;
  final String? value;
  final bool modified;
  final String? errorText;
  final ValueChanged<String> onChanged;

  const DateFieldWidget({
    super.key,
    required this.label,
    required this.value,
    required this.modified,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value != null ? DateTime.parse(value!) : DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
        );

        if (picked != null) {
          onChanged(picked.toIso8601String());
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          isDense: true, // ⭐ Aquí sí es válido
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13),
          errorText: errorText,
          errorStyle: const TextStyle(fontSize: 11),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          fillColor: modified ? Colors.orange.shade100 : null,
          filled: modified,
          prefixIcon: modified
              ? const Icon(
                  Icons.warning_amber,
                  color: Colors.orange,
                  size: 18,
                )
              : null,
          prefixIconConstraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
        ),
        child: Text(
          value != null ? value!.substring(0, 10) : "Seleccione una fecha",
          style: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }
}