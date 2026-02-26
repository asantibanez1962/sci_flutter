import 'package:flutter/material.dart';
import '../../../models/field_definition.dart';
import '../../lookup_autocomplete.dart';
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
    // ⭐ Lookup con diálogo (compacto)
    if (field.dataType == "lookup" && field.lookupDisplayFields != null) {
      return Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: TextEditingController(
                text: lookupMap[value] ?? "",
              ),
              readOnly: true,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                labelText: field.label,
                labelStyle: const TextStyle(fontSize: 13),
                errorStyle: const TextStyle(fontSize: 11),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                fillColor: isModified ? Colors.orange.shade100 : null,
                filled: isModified,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search, size: 18),
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
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

    // ⭐ Lookup autocomplete (compacto)
    if (field.dataType == "lookup" && field.isAutocomplete) {
      return LookupAutocomplete(
        label: field.label,
        lookupMap: lookupMap,
        value: value as int?,
        isModified: isModified,
        onChanged: (v) => onChanged(v),
        fontSize: 13,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      );
    }

    // ⭐ Lookup dropdown (compacto)
    if (field.dataType == "lookup") {
      return DropdownButtonFormField<int>(
        initialValue: value as int?,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          isDense: true,
          labelText: field.label,
          labelStyle: const TextStyle(fontSize: 13),
          errorStyle: const TextStyle(fontSize: 11),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          fillColor: isModified ? Colors.orange.shade100 : null,
          filled: isModified,
        ),
        items: lookupMap.entries
            .map(
              (e) => DropdownMenuItem(
                value: e.key,
                child: Text(
                  e.value,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            )
            .toList(),
        onChanged: (v) => onChanged(v),
      );
    }

    throw Exception("LookupFieldBuilder usado con field no lookup");
  }
}