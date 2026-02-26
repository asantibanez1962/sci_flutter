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
          labelText: label,
          errorText: errorText,
          border: const OutlineInputBorder(),
          fillColor: modified ? Colors.orange.shade100 : null,
          filled: modified,
          prefixIcon: modified
              ? const Icon(Icons.warning_amber, color: Colors.orange)
              : null,
        ),
        child: Text(
          value != null
              ? value!.substring(0, 10)
              : "Seleccione una fecha",
        ),
      ),
    );
  }
}