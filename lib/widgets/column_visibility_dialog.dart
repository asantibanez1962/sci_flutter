import 'package:flutter/material.dart';
import '../models/column_definition.dart';

class ColumnVisibilityDialog extends StatefulWidget {
  final List<ColumnDefinition> columns;

  const ColumnVisibilityDialog({
    super.key,
    required this.columns,
  });

  @override
  State<ColumnVisibilityDialog> createState() => _ColumnVisibilityDialogState();
}

class _ColumnVisibilityDialogState extends State<ColumnVisibilityDialog> {
  final TextEditingController _searchController = TextEditingController();
  late List<ColumnDefinition> filtered;

  @override
  void initState() {
    super.initState();
    filtered = List.from(widget.columns);
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilter);
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final q = _searchController.text.toLowerCase().trim();

    setState(() {
      if (q.isEmpty) {
        filtered = List.from(widget.columns);
      } else {
        filtered = widget.columns
            .where((c) => c.label.toLowerCase().contains(q))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        "Columnas visibles",
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),

      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ⭐ Barra de búsqueda compacta
            TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                labelText: "Buscar columna",
                labelStyle: const TextStyle(fontSize: 13),
                prefixIcon: const Icon(Icons.search, size: 18),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ⭐ Lista compacta con scroll
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final col = filtered[i];

                    return MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: col.visible
                              ? Colors.blue.withOpacity(0.06)
                              : Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 28,
                              height: 28,
                              child: Checkbox(
                                value: col.visible,
                                onChanged: (v) =>
                                    setState(() => col.visible = v ?? false),
                                visualDensity: const VisualDensity(
                                    horizontal: -4, vertical: -4),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                col.label,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
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