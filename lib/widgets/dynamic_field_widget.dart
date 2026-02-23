import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DynamicFieldWidget extends StatelessWidget {
  final String label;
  final String fieldType; // text, number, bool, date, dropdown, autocomplete
  final TextEditingController? controller;
  final dynamic value;
  final Function(dynamic) onChanged;
  final List<Map<String, dynamic>>? options; // para dropdown/autocomplete

  const DynamicFieldWidget({
    super.key,
    required this.label,
    required this.fieldType,
    this.controller,
    this.value,
    required this.onChanged,
    this.options,
  });

  @override
  Widget build(BuildContext context) {
    switch (fieldType) {
      case "text":
        return _buildTextField();

      case "number":
        return _buildNumberField();

      case "bool":
        return _buildBooleanField();

      case "date":
        return _buildDateField(context);

      case "dropdown":
        return _buildDropdownField();

      case "autocomplete":
        return _buildAutocompleteField();

      default:
        return Text("Tipo no soportado: $fieldType");
    }
  }

  // ---------------- TEXT ----------------
  Widget _buildTextField() {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
    );
  }

  // ---------------- NUMBER ----------------
  Widget _buildNumberField() {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
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

  // ---------------- BOOLEAN ----------------
 /* Widget _buildBooleanField() {
    return SwitchListTile(
      title: Text(label),
      value: value ?? false,
      onChanged: onChanged,
    );
  }*/
  Widget _buildBooleanField() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      Switch(
        value: value ?? false,
        onChanged: onChanged,
      ),
      SizedBox(width: 8),
      Text(label),
    ],
  );
}


  // ---------------- DATE ----------------
  Widget _buildDateField(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
        );
        if (picked != null) onChanged(picked.toIso8601String());
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Text(
          value != null
              ? value.toString().substring(0, 10)
              : "Seleccione una fecha",
        ),
      ),
    );
  }

  // ---------------- DROPDOWN ----------------
  Widget _buildDropdownField() {
    return DropdownButtonFormField(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      initialValue: value,
      items: options?.map((opt) {
        return DropdownMenuItem(
          value: opt["value"],
          child: Text(opt["label"]),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  // ---------------- AUTOCOMPLETE ----------------
  Widget _buildAutocompleteField() {
    return Autocomplete<Map<String, dynamic>>(
      displayStringForOption: (opt) => opt["label"],
      optionsBuilder: (text) {
        if (text.text.isEmpty) return const Iterable.empty();
        return options!.where((opt) =>
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
          ),
        );
      },
    );
  }
}