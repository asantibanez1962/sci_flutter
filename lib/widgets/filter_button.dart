import 'package:flutter/material.dart';
import '../filters/column_filter.dart';
import '../widgets/filter_dialog.dart'; // o donde tengas el diálogo

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
    return IconButton(
     icon: Icon(
        Icons.filter_alt,
        color: hasFilter ? Colors.blue : Colors.grey,
      ),

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
          onFilter(result); // ← ColumnFilter
        }
      },
    );
  }
}