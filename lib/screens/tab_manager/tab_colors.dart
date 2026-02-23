import 'package:flutter/material.dart';
import 'tab_type.dart';
Color tabColor(TabType type) {
  switch (type) {
    case TabType.entities: return Colors.blue.shade700;
    case TabType.list: return Colors.green.shade700;
    case TabType.edit: return Colors.orange.shade700;
    case TabType.create: return Colors.purple.shade700;
  }
}
