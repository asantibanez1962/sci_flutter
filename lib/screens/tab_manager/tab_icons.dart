import 'package:flutter/material.dart';
import 'tab_type.dart';
IconData tabIcon(TabType type) {
  switch (type) {
    case TabType.entities: return Icons.home;
    case TabType.list: return Icons.table_chart;
    case TabType.edit: return Icons.edit;
    case TabType.create: return Icons.add_circle;
  }
}

