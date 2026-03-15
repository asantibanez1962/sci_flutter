import 'package:flutter/material.dart';

class BooleanField extends StatelessWidget {
  final String label;
  final bool value;
  final bool modified;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final String? errorText;

  const BooleanField({
    super.key,
    required this.label,
    required this.value,
    required this.modified,
    required this.enabled,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    final enabledColor = onSurface;
    final disabledColor = onSurface.withOpacity(0.38); // ⭐ igual que lookup

    // ⭐ color del label según estado
    final labelColor = errorText != null
        ? theme.colorScheme.error
        : (enabled ? onSurface : disabledColor);

    return TextFormField(
      enabled: enabled,
      readOnly: true,
      decoration: InputDecoration(
        isDense: true,
        errorText: errorText,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
border: OutlineInputBorder(
  borderRadius: BorderRadius.circular(4),
),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: enabledColor, width: 0.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: disabledColor, width: 0.30),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: theme.colorScheme.error, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: theme.colorScheme.error, width: 2.0),
        ),

        fillColor: modified ? Colors.orange.shade100 : null,
        filled: modified,

        prefixIconConstraints:
            const BoxConstraints(minWidth: 0, minHeight: 0),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 4, right: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,          // ⭐ tamaño idéntico a lookup
                  color: labelColor,     // ⭐ disabled / enabled / error
                ),
              ),
              const SizedBox(width: 4),
              Transform.scale(
                scale: 0.85,
                child: Checkbox(
                  value: value,
                  onChanged: enabled
                      ? (v) => onChanged(v ?? false)
                      : null,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity:
                      const VisualDensity(horizontal: -4, vertical: -4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}