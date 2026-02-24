import 'package:flutter/material.dart';
import '../../../models/field_definition.dart';
import '../../../widgets/lookup_autoocomplete.dart';
import '../../../widgets/lookupdialog.dart';

typedef LookupMap = Map<int, String>;

class LookupFieldBuilder {
  static Widget buildLookupField({
    required BuildContext context,
    required FieldDefinition field,
    required dynamic value,
    required LookupMap lookupMap,
    required bool isModified,
    required void Function(dynamic) onChanged,
    required Future<List<Map<String, dynamic>>> Function() loadDialogRows,
  }) {
    // lookup complejo con diálogo
    if (field.dataType == "lookup" && field.lookupDisplayFields != null) {
      return Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: TextEditingController(
                text: lookupMap[value] ?? "",
              ),
              readOnly: true,
              decoration: InputDecoration(
                labelText: field.label,
                border: const OutlineInputBorder(),
                enabledBorder: const OutlineInputBorder(),
                disabledBorder: const OutlineInputBorder(),
                fillColor: isModified ? Colors.orange.shade100 : null,
                filled: isModified,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final rows = await loadDialogRows();

              final selected = await showDialog(
                context: context,
                builder: (_) => LookupDialog(
                  title: field.label,
                  rows: rows,
                  displayFields: field.lookupDisplayFields!,
                ),
              );

              if (selected != null) {
                onChanged(selected["id"]);
              }
            },
          ),
        ],
      );
    }

    // lookup autocomplete
    if (field.dataType == "lookup" && field.isAutocomplete) {
      return LookupAutocomplete(
        label: field.label,
        lookupMap: lookupMap,
        value: value as int?,
        isModified: isModified,
        onChanged: (v) => onChanged(v),
      );
    }

    // lookup normal (dropdown)
    if (field.dataType == "lookup") {
      return DropdownButtonFormField<int>(
        initialValue: value as int?,
        decoration: InputDecoration(
          labelText: field.label,
          border: const OutlineInputBorder(),
          fillColor: isModified ? Colors.orange.shade100 : null,
          filled: isModified,
        ),
        items: lookupMap.entries
            .map(
              (e) => DropdownMenuItem(
                value: e.key,
                child: Text(e.value),
              ),
            )
            .toList(),
        onChanged: (v) => onChanged(v),
      );
    }

    throw Exception("LookupFieldBuilder usado con field no lookup");
  }
}