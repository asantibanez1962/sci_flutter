import 'package:flutter/material.dart';
import 'dynamic_list_controller.dart';

class DynamicListHeader extends StatelessWidget implements PreferredSizeWidget {
  final DynamicListController controller;

  const DynamicListHeader({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final hiddenCount = controller.columns.where((c) => !c.visible).length;

    return AppBar(
      // ⭐ Compactación ERP
      toolbarHeight: 42,
      titleSpacing: 8,
      elevation: 0,
      backgroundColor: Colors.grey[100],

      titleTextStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),

      iconTheme: const IconThemeData(size: 18, color: Colors.black87),

      actionsIconTheme: const IconThemeData(size: 18),

      actions: [
        if (controller.columnFilters.isNotEmpty)
          IconButton(
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(6),
              minimumSize: const Size(32, 32),
            ),
            icon: const Icon(Icons.filter_alt_off),
            onPressed: controller.clearAllFilters,
          ),

        Stack(
          children: [
            IconButton(
              style: IconButton.styleFrom(
                padding: const EdgeInsets.all(6),
                minimumSize: const Size(32, 32),
              ),
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
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    hiddenCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
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
  Size get preferredSize => const Size.fromHeight(42);
}