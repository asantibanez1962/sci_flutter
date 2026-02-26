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

  String _formatForDisplay(String iso) {
    try {
      final normalized = iso.replaceFirst("T", " ");
      final date = DateTime.tryParse(normalized);
      if (date == null) return iso;

      // ⭐ Formato MM/dd/yyyy
      return "${_two(date.day)}/${_two(date.month)}/${date.year}";
    } catch (_) {
      return iso;
    }
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        /*final initial = value != null
            ? DateTime.tryParse(value!.replaceFirst("T", " ")) ?? DateTime.now()
            : DateTime.now();*/

            final picked = await showDatePicker(
              context: context,
              locale: const Locale('es', 'CR'), // ⭐ fuerza día/mes/año
              initialDate: value != null
                  ? DateTime.parse(value!.replaceFirst("T", " "))
                  : DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
            );


        if (picked != null) {
          // ⭐ Enviar ISO al backend
          onChanged(picked.toIso8601String());
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          isDense: true,
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

        // ⭐ Mostrar MM/dd/yyyy
        child: Text(
          value != null   ? _formatForDisplay(value!) : "Seleccione una fecha",
          style: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }
}