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
        const PopupMenuItem(
          value: "asc",
          child: Row(
            children: [
              Icon(Icons.arrow_upward, size: 16),
              SizedBox(width: 6),
              Text("Ordenar ascendente"),
            ],
          ),
        ),
        const PopupMenuItem(
          value: "desc",
          child: Row(
            children: [
              Icon(Icons.arrow_downward, size: 16),
              SizedBox(width: 6),
              Text("Ordenar descendente"),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: "filter",
          child: Row(
            children: [
              Icon(Icons.filter_alt, size: 16),
              SizedBox(width: 6),
              Text("Filtrar…"),
            ],
          ),
        ),
        if (hasFilter)
          const PopupMenuItem(
            value: "clear",
            child: Row(
              children: [
                Icon(Icons.filter_alt_off, size: 16),
                SizedBox(width: 6),
                Text("Quitar filtro"),
              ],
            ),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: "empty",
          child: Text("Vacío"),
        ),
        const PopupMenuItem(
          value: "notEmpty",
          child: Text("No vacío"),
        ),
        const PopupMenuItem(
          value: "equals",
          child: Text("Igual a…"),
        ),
        const PopupMenuItem(
          value: "notEquals",
          child: Text("Distinto de…"),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: "hideColumn",
          child: Text("Ocultar columna"),
        ),
        if (isDate) ...[
          const PopupMenuDivider(),
          const PopupMenuItem(value: "today", child: Text("Hoy")),
          const PopupMenuItem(value: "yesterday", child: Text("Ayer")),
          const PopupMenuItem(value: "thisWeek", child: Text("Esta semana")),
          const PopupMenuItem(value: "thisMonth", child: Text("Este mes")),
        ],
      ],
    );
  }
}