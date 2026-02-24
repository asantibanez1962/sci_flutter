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
        return options.where((opt) =>
            opt["label"].toLowerCase().contains(text.text.toLowerCase()));
      },
      onSelected: (opt) => onChanged(opt["value"]),
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: textController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            enabledBorder: const OutlineInputBorder(),
            focusedBorder: const OutlineInputBorder(),
            fillColor: modified ? Colors.orange.shade100 : null,
            filled: modified,
            prefixIcon: modified
                ? const Icon(Icons.warning_amber, color: Colors.orange)
                : null,
          ),
        );
      },
    );
  }
}