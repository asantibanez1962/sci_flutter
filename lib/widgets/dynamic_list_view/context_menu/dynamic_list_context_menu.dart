import 'package:flutter/material.dart';

class DynamicListContextMenu {
  static Future<String?> show({
    required BuildContext context,
    required Offset position,
    required String column,
    required bool hasFilter,
    required bool isDate,
  }) {
    return showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: [
        PopupMenuItem(
          value: "asc",
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: const [
              Icon(Icons.arrow_upward, size: 16),
              SizedBox(width: 6),
              Text("Ordenar ascendente", style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: "desc",
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: const [
              Icon(Icons.arrow_downward, size: 16),
              SizedBox(width: 6),
              Text("Ordenar descendente", style: TextStyle(fontSize: 13)),
            ],
          ),
        ),

        const PopupMenuDivider(),

        PopupMenuItem(
          value: "filter",
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: const [
              Icon(Icons.filter_alt, size: 16),
              SizedBox(width: 6),
              Text("Filtrar…", style: TextStyle(fontSize: 13)),
            ],
          ),
        ),

        if (hasFilter)
          PopupMenuItem(
            value: "clear",
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: const [
                Icon(Icons.filter_alt_off, size: 16),
                SizedBox(width: 6),
                Text("Quitar filtro", style: TextStyle(fontSize: 13)),
              ],
            ),
          ),

        const PopupMenuDivider(),

        const PopupMenuItem(
          value: "empty",
          height: 28,
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text("Vacío", style: TextStyle(fontSize: 13)),
        ),
        const PopupMenuItem(
          value: "notEmpty",
          height: 28,
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text("No vacío", style: TextStyle(fontSize: 13)),
        ),
        const PopupMenuItem(
          value: "equals",
          height: 28,
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text("Igual a…", style: TextStyle(fontSize: 13)),
        ),
        const PopupMenuItem(
          value: "notEquals",
          height: 28,
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text("Distinto de…", style: TextStyle(fontSize: 13)),
        ),

        const PopupMenuDivider(),

        const PopupMenuItem(
          value: "hideColumn",
          height: 28,
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text("Ocultar columna", style: TextStyle(fontSize: 13)),
        ),

        if (isDate) ...[
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: "today",
            height: 28,
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text("Hoy", style: TextStyle(fontSize: 13)),
          ),
          const PopupMenuItem(
            value: "yesterday",
            height: 28,
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text("Ayer", style: TextStyle(fontSize: 13)),
          ),
          const PopupMenuItem(
            value: "thisWeek",
            height: 28,
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text("Esta semana", style: TextStyle(fontSize: 13)),
          ),
          const PopupMenuItem(
            value: "thisMonth",
            height: 28,
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text("Este mes", style: TextStyle(fontSize: 13)),
          ),
        ],
      ],
    );
  }
}