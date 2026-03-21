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
    
  if (field.dataType == "lookup" && field.lookupDisplayFields != null) {
    return FormField<dynamic>(
      key:ValueKey(value),
    initialValue: value,
    validator: (v) {
      //debugPrint('Validando lookup ${field.name} -> $v');
      return FieldValidator.validate(field, v);
    },
    builder: (state) {
        final theme = Theme.of(context);
        final onSurface = theme.colorScheme.onSurface;
        final disabledColor = onSurface.withAlpha((0.38 * 255).round()); // color tenue igual que Material
        final enabledColor =onSurface; //.withAlpha((1.5 * 255).round());
        // Asegúrate de que 'enabled' refleja el estado real (true/false)
        final isEnabled = enabled; // tu variable existente
        final displayText = lookupMap[state.value] ?? '';
        final displayTextStyle = const TextStyle(fontSize: 13); // igual que tu TextFormField


        if (state.value != value) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (state.mounted) {
          //    debugPrint('  -> sincronizando antes de state.didChange(${value}) para ${field.name}');
              state.didChange(value);
              // Pedimos al padre que valide ahora que el FormField está sincronizado
              requestValidation?.call();
            //  debugPrint('  -> después de didChange para ${field.name}');

          //   debugPrint('  -> requestValidation llamada para ${field.name}');
            }
          });
        }


      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: isEnabled
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
                     isEmpty: displayText.isEmpty,

                    decoration: InputDecoration(
                      isDense: true,
                      enabled: isEnabled,
                      labelText: field.label,
                      labelStyle: TextStyle(fontSize: 13, color: isEnabled ? null : disabledColor),
                      errorText: state.errorText,
                      errorStyle: const TextStyle(fontSize: 11),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: onSurface, width: 1.0)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: enabledColor, width: 1.0)),
                      disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: disabledColor, width: 0.30)),
                      focusedBorder: isEnabled
                          ? (state.hasError
                              ? OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: theme.colorScheme.error, width: 2.0))
                              : OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: theme.colorScheme.primary, width: 2.0)))
                          : null,

                      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: theme.colorScheme.error, width: 1.0)),
                      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: theme.colorScheme.error, width: 2.0)),
                      fillColor: isModified ? Colors.orange.shade100 : null,
                      filled: isModified,// ? true : deco.filled ?? false,
                    ),
                      child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            displayText,
                            style: displayTextStyle.copyWith(color: isEnabled ? onSurface : disabledColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
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
        ],
      );
    },
  );
} 

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