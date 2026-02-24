import 'package:flutter/material.dart';

class LookupAutocomplete extends StatefulWidget {
  final String label;
  final Map<int, String> lookupMap;
  final int? value;
  final Function(int?) onChanged;
 final bool isModified;


  const LookupAutocomplete({
    super.key,
    required this.label,
    required this.lookupMap,
    required this.value,
    required this.onChanged,
    this.isModified = false, // ⭐ default

  });

  @override
  State<LookupAutocomplete> createState() => _LookupAutocompleteState();
}

class _LookupAutocompleteState extends State<LookupAutocomplete> {
  bool userIsTyping = false;

  @override
  Widget build(BuildContext context) {
    final items = widget.lookupMap.entries.toList();

    return Autocomplete<MapEntry<int, String>>(
      displayStringForOption: (opt) => opt.value,

      // ⭐ Mostrar el valor actual en el campo
      initialValue: widget.value != null
          ? TextEditingValue(text: widget.lookupMap[widget.value] ?? "")
          : const TextEditingValue(),

      // ⭐ Lógica de filtrado ERP-style
      optionsBuilder: (text) {
        // Si el usuario NO está escribiendo → mostrar TODAS las opciones
        if (!userIsTyping) {
          return items;
        }

        // Si está escribiendo → filtrar
        return items.where((e) =>
            e.value.toLowerCase().contains(text.text.toLowerCase()));
      },

      onSelected: (opt) {
        widget.onChanged(opt.key);
        userIsTyping = false; // reset
      },

      fieldViewBuilder: (context, textcontroller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: textcontroller,
          focusNode: focusNode,
          decoration: InputDecoration(
                labelText: widget.label,
                border: const OutlineInputBorder(),
                enabledBorder: const OutlineInputBorder(),
                focusedBorder: const OutlineInputBorder(),

                // ⭐ Color dinámico según cambios
                fillColor: widget.isModified ? Colors.orange.shade100 : null,
                filled: widget.isModified,
              ),

          // ⭐ Permitir escribir para filtrar
          readOnly: false,

          onTap: () {
            // ⭐ Al hacer tap → mostrar TODAS las opciones
            setState(() => userIsTyping = false);
            focusNode.requestFocus();
          },

          onChanged: (_) {
            // ⭐ Si escribe → activar filtrado
            setState(() => userIsTyping = true);
          },

          //decoration: InputDecoration(labelText: widget.label),
        );
      },
    );
  }
}