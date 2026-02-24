import 'package:flutter/material.dart';
import '../widgets/dynamic_form_view/dynamic_form_view.dart';
class TabItem {
  final String id;
  final String title;
  final Widget view;
  final IconData icon;
  final Color color;
  final bool closable;

  final GlobalKey<DynamicFormViewState>? formKey;

  TabItem({
    required this.id,
    required this.title,
    required this.view,
    required this.icon,
    required this.color,
    this.closable = true,
    this.formKey, // ⭐ ahora sí inicializado
  });
}