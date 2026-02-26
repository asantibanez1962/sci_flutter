import 'package:flutter/material.dart';

class LookupAutocomplete extends StatefulWidget {
  final String label;
  final Map<int, String> lookupMap;
  final int? value;
  final Function(int?) onChanged;
  final bool isModified;

  // ⭐ Parámetros para densidad visual
  final double fontSize;
  final EdgeInsets padding;

  const LookupAutocomplete({
    super.key,
    required this.label,
    required this.lookupMap,
    required this.value,
    required this.onChanged,
    this.isModified = false,
    this.fontSize = 13,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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

      initialValue: widget.value != null
          ? TextEditingValue(text: widget.lookupMap[widget.value] ?? "")
          : const TextEditingValue(),

      optionsBuilder: (text) {
        if (!userIsTyping) return items;
        return items.where(
          (e) => e.value.toLowerCase().contains(text.text.toLowerCase()),
        );
      },

      onSelected: (opt) {
        widget.onChanged(opt.key);
        userIsTyping = false;
      },

      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: textController,
          focusNode: focusNode,
          style: TextStyle(fontSize: widget.fontSize),

          decoration: InputDecoration(
            isDense: true,
            labelText: widget.label,
            labelStyle: TextStyle(fontSize: widget.fontSize),
            contentPadding: widget.padding,
            errorStyle: const TextStyle(fontSize: 11),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
            ),

            fillColor: widget.isModified ? Colors.orange.shade100 : null,
            filled: widget.isModified,
          ),

          readOnly: false,

          onTap: () {
            setState(() => userIsTyping = false);
            focusNode.requestFocus();
          },

          onChanged: (_) {
            setState(() => userIsTyping = true);
          },
        );
      },
    );
  }
}