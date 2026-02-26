import 'package:flutter/material.dart';
import '../filters/column_filter.dart';
import '../widgets/filter_dialog.dart';

class FilterButton extends StatelessWidget {
  final String field;
  final String fieldType;
  final ColumnFilter? filter;
  final void Function(ColumnFilter filter) onFilter;

  const FilterButton({
    super.key,
    required this.field,
    required this.fieldType,
    required this.onFilter,
    this.filter,
  });

  @override
  Widget build(BuildContext context) {
    final hasFilter = filter != null;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        decoration: BoxDecoration(
          color: hasFilter ? Colors.blue.withOpacity(0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: hasFilter ? Colors.blue : Colors.grey.shade400,
            width: hasFilter ? 1.2 : 1,
          ),
        ),
        child: IconButton(
          iconSize: 18, // ⭐ Compacto
          padding: const EdgeInsets.all(4), // ⭐ Compacto
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
          icon: Icon(
            Icons.filter_alt,
            color: hasFilter ? Colors.blue : Colors.grey.shade700,
          ),
          tooltip: hasFilter ? "Filtro aplicado" : "Agregar filtro",
          onPressed: () async {
            final result = await showDialog<ColumnFilter>(
              context: context,
              builder: (_) => FilterDialog(
                field: field,
                fieldType: fieldType,
                filter: filter,
              ),
            );

            if (result != null) {
              onFilter(result);
            }
          },
        ),
      ),
    );
  }
}