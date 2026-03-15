import 'package:flutter/material.dart';
import '../../../models/field_definition.dart';
import '../../lookup_autocomplete.dart';
import '../../../widgets/lookupdialog.dart';
import '../validation/field_validator.dart';


typedef LookupMap = Map<int, String>;

class LookupFieldBuilder {
  static Widget buildLookupField({
    required BuildContext context,
    required FieldDefinition field,
    required dynamic value,
    required LookupMap lookupMap,
    required bool isModified,
    required void Function(dynamic) onChanged,
    required Future<List<Map<String, dynamic>>> Function() loadDialogRows,
     bool enabled = true,
     VoidCallback? requestValidation, // <-- nuevo
  }) {
    
  //para poner en rojo si es requerido
  // ⭐ Lookup con diálogo (compacto) con rojo
// Reemplaza la rama actual del lookup por este bloque dentro de LookupFieldBuilder.buildLookupField
if (field.dataType == "lookup" && field.lookupDisplayFields != null) {
  // lookupMap ya viene como parámetro (lookupMap)
  return FormField<dynamic>(
    initialValue: value,
    validator: (v) {
      debugPrint('Validando lookup ${field.name} -> $v');
      return FieldValidator.validate(field, v);
    },
    builder: (state) {
        // Sincronizar state.value con el value externo si difieren
        // Debug: ver estado inicial del FormField
  debugPrint('Lookup builder ${field.name} mounted=${state.mounted} state.value=${state.value} external value=$value');
// Bordes y colores (declarar aquí, antes del return)
final theme = Theme.of(context);
final decoTheme = theme.inputDecorationTheme;
//final textStyle = theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 16);
final errorColor = theme.colorScheme.error;



// Bordes: preferir los del tema si existen, sino fallback con anchos iguales a TextFormField
final enabledBorder = OutlineInputBorder(
  borderRadius: BorderRadius.circular(4),
  borderSide: BorderSide(
    color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
    width: 1.0,
  ),
);

final focusedBorder = decoTheme.focusedBorder ??
    OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: theme.colorScheme.primary, width: 2.0));
final errorBorder = decoTheme.errorBorder ??
    OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: errorColor, width: 1.0));
final focusedErrorBorder = decoTheme.focusedErrorBorder ??
    OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: errorColor, width: 2.0));

  if (state.value != value) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.mounted) {
        debugPrint('  -> sincronizando antes de state.didChange(${value}) para ${field.name}');
        state.didChange(value);
         // Pedimos al padre que valide ahora que el FormField está sincronizado
        requestValidation?.call();
        debugPrint('  -> después de didChange para ${field.name}');

        debugPrint('  -> requestValidation llamada para ${field.name}');
      }
    });
  }


      final displayText = lookupMap[state.value] ?? '';
      final displayTextStyle = const TextStyle(fontSize: 13); // coincide con tu TextFormField


      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: enabled
                      ? () async {
                          final rows = await loadDialogRows();
                          final selected = await showDialog(
                            context: context,
                            builder: (_) => LookupDialog(
                              title: field.label,
                              rows: rows,
                              displayFields: field.lookupDisplayFields!,
                            ),
                          );
                          if (selected != null) {
                            state.didChange(selected['id']);
                            onChanged(selected['id']);
                          }
                        }
                      : null,
                  child: InputDecorator(
                    
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: field.label,
                      labelStyle: const TextStyle(fontSize: 13),
                      errorText: state.errorText,
                      errorStyle: const TextStyle(fontSize: 11),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      //border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                      border: decoTheme.border ?? enabledBorder,
                  enabledBorder: enabledBorder,
                  // si hay error, forzamos el focusedBorder a focusedErrorBorder para que el rojo tenga el mismo grosor
    focusedBorder: state.hasError ? focusedErrorBorder : focusedBorder,
    errorBorder: errorBorder,
    focusedErrorBorder: focusedErrorBorder,

                      fillColor: isModified ? Colors.orange.shade100 : null,
                      filled: isModified,
                    ),
                      child: Align(
    alignment: Alignment.centerLeft,
    child: Text(
      displayText,
      style: displayTextStyle, // mismo tamaño y peso que TextFormField
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
  ),

                    /*

                    child: Text(
                      displayText,
                      style: const TextStyle(fontSize: 13),
                    ),*/
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.search, size: 18),
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: enabled
                    ? () async {
                        final rows = await loadDialogRows();
                        final selected = await showDialog(
                          context: context,
                          builder: (_) => LookupDialog(
                            title: field.label,
                            rows: rows,
                            displayFields: field.lookupDisplayFields!,
                          ),
                        );
                        if (selected != null) {
                          state.didChange(selected['id']);
                          onChanged(selected['id']);
                        }
                      }
                    : null,
              ),
            ],
          ),
          /*if (state.hasError) salia doble el mensaje
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 12),
              child: Text(state.errorText ?? '', style: const TextStyle(color: Colors.red, fontSize: 11)),
            ),*/
        ],
      );
    },
  );
} 

   // ⭐ Lookup con diálogo (compacto)
    /*sin rojo
    if (field.dataType == "lookup" && field.lookupDisplayFields != null) {
      return Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: TextEditingController(
                text: lookupMap[value] ?? "",
              ),
              readOnly: true,
              enabled: enabled,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                labelText: field.label,
                labelStyle: const TextStyle(fontSize: 13),
                errorStyle: const TextStyle(fontSize: 11),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                fillColor: isModified ? Colors.orange.shade100 : null,
                filled: isModified,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search, size: 18),
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            onPressed: enabled ? () async {
              final rows = await loadDialogRows();

              final selected = await showDialog(
                context: context,
                builder: (_) => LookupDialog(
                  title: field.label,
                  rows: rows,
                  displayFields: field.lookupDisplayFields!,
                ),
              );

              if (selected != null) {
                onChanged(selected["id"]);
              }
            }:null,
          ),
        ],
      );
    }
*/
    // ⭐ Lookup autocomplete (compacto)
    if (field.dataType == "lookup" && field.isAutocomplete) {
      return LookupAutocomplete(
        label: field.label,
        lookupMap: lookupMap,
        value: value as int?,
        isModified: isModified,
        enabled: enabled,                   
        onChanged: enabled
          ? (v) => onChanged(v)
          : (_) {},

        fontSize: 13,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      );
    }

    // ⭐ Lookup dropdown (compacto)
    if (field.dataType == "lookup") {
      return DropdownButtonFormField<int>(
        initialValue: value as int?,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          isDense: true,
          labelText: field.label,
          labelStyle: const TextStyle(fontSize: 13),
          errorStyle: const TextStyle(fontSize: 11),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          fillColor: isModified ? Colors.orange.shade100 : null,
          filled: isModified,
        ),
        items: lookupMap.entries
            .map(
              (e) => DropdownMenuItem(
                value: e.key,
                child: Text(
                  e.value,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            )
            .toList(),
        onChanged: enabled ? (v) => onChanged(v) : null,
      );
    }

    throw Exception("LookupFieldBuilder usado con field no lookup");
  }
}