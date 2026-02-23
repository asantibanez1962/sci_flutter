import 'package:flutter/material.dart';
import '../models/column_definition.dart';

class ColumnVisibilityDialog extends StatefulWidget {
  final List<ColumnDefinition> columns;

  const ColumnVisibilityDialog({
    super.key,
    required this.columns,
  });

  @override
  State<ColumnVisibilityDialog> createState() =>
      _ColumnVisibilityDialogState();
}

class _ColumnVisibilityDialogState extends State<ColumnVisibilityDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        "Columnas visibles",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 300,
        child: ListView(
          shrinkWrap: true,
          children: widget.columns.map((col) {
            return SizedBox(
              height: 32,
              child: CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                title: Text(col.label, style: const TextStyle(fontSize: 13)),
                value: col.visible,
                onChanged: (v) => setState(() => col.visible = v!),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            );
          }).toList(),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      actions: [
        TextButton(
          child: const Text("Cancelar", style: TextStyle(fontSize: 13)),
          onPressed: () => Navigator.pop(context, false),
        ),
        ElevatedButton(
          child: const Text("Aplicar", style: TextStyle(fontSize: 13)),
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
  }
}