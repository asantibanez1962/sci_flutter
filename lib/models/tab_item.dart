import 'package:flutter/material.dart';
class TabItem {
  final String id;
  final String title;
  final Widget view;
  final IconData icon;
  final Color color;
  final bool closable;

  TabItem({
    required this.id,
    required this.title,
    required this.view,
    required this.icon,
    required this.color,
    this.closable = true,
  });
}