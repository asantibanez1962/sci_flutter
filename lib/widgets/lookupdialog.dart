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
  final FocusNode _searchFocus = FocusNode();
  final ScrollController verticalController = ScrollController();
  final ScrollController horizontalController = ScrollController();

  int? hoveredIndex;
  int? selectedIndex;
  String sortColumn = "";
  bool sortAsc = true;
String? hoveredHeader;

  @override
  void initState() {
    super.initState();
    filteredRows = List<Map<String, dynamic>>.from(widget.rows);
    _searchController.addListener(_applyFilter);

    // ⭐ Foco automático
    Future.delayed(Duration.zero, () {
      _searchFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilter);
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase().trim();

    setState(() {
      if (query.isEmpty) {
        filteredRows = List<Map<String, dynamic>>.from(widget.rows);
      } else {
        filteredRows = widget.rows.where((row) {
          return widget.displayFields.any((f) =>
              (row[f]?.toString().toLowerCase() ?? "").contains(query));
        }).toList();
      }
    });
  }

  void _sortBy(String field) {
    setState(() {
      if (sortColumn == field) {
        sortAsc = !sortAsc;
      } else {
        sortColumn = field;
        sortAsc = true;
      }

      filteredRows.sort((a, b) {
        final va = a[field]?.toString() ?? "";
        final vb = b[field]?.toString() ?? "";
        return sortAsc ? va.compareTo(vb) : vb.compareTo(va);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),

      content: SizedBox(
        width: 700,
        height: 420,
        child: Column(
          children: [
            // ⭐ Campo de búsqueda compacto
            TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                labelText: "Buscar",
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

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Mostrando ${filteredRows.length} resultados",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),

            const SizedBox(height: 6),

            Expanded(
              child: Scrollbar(
                controller: verticalController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: verticalController,
                  scrollDirection: Axis.vertical,
                  child: Scrollbar(
                    controller: horizontalController,
                    thumbVisibility: true,
                    notificationPredicate: (notif) =>
                        notif.metrics.axis == Axis.horizontal,
                    child: SingleChildScrollView(
                      controller: horizontalController,
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        dataRowMinHeight: 32,
                        dataRowMaxHeight: 36,
                        headingRowHeight: 36,
                        columnSpacing: 12,
                        horizontalMargin: 8,
                          columns: widget.displayFields.map((f) {
                            final isHovered = hoveredHeader == f;

                            return DataColumn(
                              label: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                onEnter: (_) => setState(() => hoveredHeader = f),
                                onExit: (_) => setState(() => hoveredHeader = null),
                                child: GestureDetector(
                                  onTap: () => _sortBy(f),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                                    decoration: BoxDecoration(
                                      color: isHovered
                                          ? Colors.blue.withValues(alpha: 0.06)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          f,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: isHovered ? Colors.blue : Colors.black,
                                          ),
                                        ),
                                        if (sortColumn == f)
                                          Icon(
                                            sortAsc ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                                            size: 18,
                                            color: Colors.blue,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                          rows: filteredRows.asMap().entries.map((entry) {
                          final i = entry.key;
                          final row = entry.value;

                          final isHovered = hoveredIndex == i;

                          return DataRow(
                            color: WidgetStateProperty.resolveWith((states) {
                              return isHovered
                                  ? Colors.blue.withValues(alpha: 0.08)
                                  : null;
                            }),
                            cells: widget.displayFields.map((f) {
                              return DataCell(
                                MouseRegion(
                                  onEnter: (_) => setState(() => hoveredIndex = i),
                                  onExit: (_) => setState(() => hoveredIndex = null),
                                  child: Text(
                                    row[f]?.toString() ?? "",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isHovered ? Colors.blue : Colors.black,
                                      fontWeight: isHovered ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                onTap: () => Navigator.pop(context, row),
                              );
                            }).toList(),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ) 
          ],
        ),
      ),

      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            "Cerrar",
            style: TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  
}
