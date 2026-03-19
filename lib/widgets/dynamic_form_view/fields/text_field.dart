import 'package:flutter/material.dart';
import '../../../models/field_definition.dart';
import '../validation/field_validator.dart';

class TextFieldWidget extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool modified;
  //final String? errorText;
  final bool enabled;                
  final ValueChanged<String> onChanged;
  final FieldDefinition? field; // nuevo: la definición del campo
  //final String? Function(String?)? validator; // nuevo
  final AutovalidateMode? autovalidateMode; // opcional



  const TextFieldWidget({
    super.key,
    required this.label,
    required this.controller,
    required this.modified,
    required this.enabled,
    required this.onChanged,
    //this.errorText,
    this.field,
    this.autovalidateMode, // = AutovalidateMode.onUserInteraction,  ///estaba disabled

  });



  @override
  Widget build(BuildContext context) {
    // Pegar dentro del build donde tengas contexto (por ejemplo en el builder del lookup)
/*debugPrint('inputDecorationTheme: ${Theme.of(context).inputDecorationTheme}');
debugPrint('textTheme.bodyMedium: ${Theme.of(context).textTheme.bodyMedium}');
debugPrint('colorScheme.onSurface: ${Theme.of(context).colorScheme.onSurface}');
debugPrint('colorScheme.error: ${Theme.of(context).colorScheme.error}');*/

final myDeco = InputDecoration(
  isDense: true,
  labelText: label,
  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
);
final borderSide = (myDeco.border is OutlineInputBorder)
    ? (myDeco.border as OutlineInputBorder).borderSide
    : null;
//debugPrint('TextFormField borderSide: $borderSide');

    return TextFormField(
      controller: controller,
      enabled: enabled,
      style: const TextStyle(fontSize: 13), // ⭐ Texto compacto
      autovalidateMode: autovalidateMode,
      decoration: InputDecoration(
        isDense: true, // ⭐ Reduce altura del TextField
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13), // ⭐ Label compacto
        //errorText: errorText,
        errorStyle: const TextStyle(fontSize: 11), // ⭐ Error compacto

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 8,
        ), // ⭐ Reduce padding interno

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
        ),

        fillColor: modified ? Colors.orange.shade100 : null,
        filled: modified,

        prefixIcon: modified
            ? const Icon(
                Icons.warning_amber,
                color: Colors.orange,
                size: 18, // ⭐ Ícono compacto
              )
            : null,
        prefixIconConstraints: const BoxConstraints(
          minWidth: 32,
          minHeight: 32,
        ), // ⭐ Evita que el ícono agrande el campo
      ),
      onChanged: onChanged,
      validator: (v) {
        if (field == null) return null;
        // debugPrint('Validando ${field!.name} -> value="$v"');
        return FieldValidator.validate(field!, v);
      },
    );
  }
  
}