import 'package:flutter/material.dart';

class AutocompleteFieldWidget extends StatelessWidget {
  final String label;
  final List<Map<String, dynamic>> options;
  final bool modified;
  final ValueChanged<dynamic> onChanged;

  const AutocompleteFieldWidget({
    super.key,
    required this.label,
    required this.options,
    required this.modified,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<Map<String, dynamic>>(
      displayStringForOption: (opt) => opt["label"],

      optionsBuilder: (text) {
        if (text.text.isEmpty) return const Iterable.empty();
        return options.where(
          (opt) => opt["label"]
              .toLowerCase()
              .contains(text.text.toLowerCase()),
        );
      },

      onSelected: (opt) => onChanged(opt["value"]),

      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: textController,
          focusNode: focusNode,
          style: const TextStyle(fontSize: 13), // ⭐ Texto compacto

          decoration: InputDecoration(
            isDense: true, // ⭐ Reduce altura
            labelText: label,
            labelStyle: const TextStyle(fontSize: 13), // ⭐ Label compacto
            errorStyle: const TextStyle(fontSize: 11),

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ), // ⭐ Padding reducido

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
        );
      },
    );
  }
}