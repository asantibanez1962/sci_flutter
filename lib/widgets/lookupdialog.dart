import 'package:flutter/material.dart';

class LookupDialog extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> rows;
  final List<String> displayFields;

  const LookupDialog({
    super.key,
    required this.title,
    required this.rows,
    required this.displayFields,
  });

  @override
  State<LookupDialog> createState() => _LookupDialogState();
}

class _LookupDialogState extends State<LookupDialog> {
  late List<Map<String, dynamic>> filteredRows;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredRows = List<Map<String, dynamic>>.from(widget.rows);
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilter);
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase().trim();

    if (query.isEmpty) {
      setState(() {
        filteredRows = List<Map<String, dynamic>>.from(widget.rows);
      });
      return;
    }

    setState(() {
      filteredRows = widget.rows.where((row) {
        for (final field in widget.displayFields) {
          final value = row[field]?.toString().toLowerCase() ?? "";
          if (value.contains(query)) return true;
        }
        return false;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: "Buscar",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: widget.displayFields
                      .map((f) => DataColumn(label: Text(f)))
                      .toList(),
                  rows: filteredRows.map((row) {
                    return DataRow(
                      cells: widget.displayFields.map((f) {
                        return DataCell(
                          Text(row[f]?.toString() ?? ""),
                          onTap: () {
                            Navigator.pop(context, row);
                          },
                        );
                      }).toList(),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cerrar"),
        ),
      ],
    );
  }
}
/* anterior
class LookupDialog extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> rows;
  final List<String> displayFields;

  const LookupDialog({
    super.key,
    required this.title,
    required this.rows,
    required this.displayFields,
  });

  @override
  State<LookupDialog> createState() => _LookupDialogState();
}

class _LookupDialogState extends State<LookupDialog> {
  String filter = "";

  @override
  Widget build(BuildContext context) {
    final filtered = widget.rows.where((row) {
      return widget.displayFields.any((f) =>
          row[f].toString().toLowerCase().contains(filter.toLowerCase()));
    }).toList();

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 600,
        height: 400,
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(labelText: "Buscar..."),
              onChanged: (v) => setState(() => filter = v),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final row = filtered[i];
                  final title = widget.displayFields
                      .map((f) => row[f].toString())
                      .join("  |  ");

                  return ListTile(
                    title: Text(title),
                    onTap: () => Navigator.pop(context, row),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
*/