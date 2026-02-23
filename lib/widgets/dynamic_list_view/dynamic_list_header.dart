import 'package:flutter/material.dart';
import 'dynamic_list_controller.dart';

class DynamicListHeader extends StatelessWidget
    implements PreferredSizeWidget {
  final DynamicListController controller;

  const DynamicListHeader({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final hiddenCount =
        controller.columns.where((c) => !c.visible).length;

    return AppBar(
      title: Text(controller.state.widget.entity.name),
      actions: [
        if (controller.columnFilters.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.filter_alt_off),
            onPressed: controller.clearAllFilters,
          ),
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.view_column),
              tooltip: hiddenCount == 0
                  ? "Todas las columnas visibles"
                  : "$hiddenCount columnas ocultas",
              onPressed: controller.openColumnVisibilityDialog,
            ),
            if (hiddenCount > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    hiddenCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}