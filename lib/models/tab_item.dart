import 'package:flutter/material.dart';
import '../widgets/dynamic_form_view/dynamic_form_view.dart';
import '../widgets/dynamic_form_view/dynamic_form_controller.dart';
class TabItem {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final bool closable;

  final Widget? view;                 // ← para pantallas normales
  final Widget Function()? builder;   // ← para formularios dinámicos

  final GlobalKey<DynamicFormViewState>? formKey;
  final Future<bool> Function()? onRequestClose;

 // 🔥 AGREGAR ESTO
  final DynamicFormController? controller;


  TabItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    this.closable = true,
    this.view,
    this.builder,
    this.formKey,
    this.onRequestClose,
     this.controller,

  });
}