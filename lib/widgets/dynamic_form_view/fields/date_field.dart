//edicion de campo fecha con picker y formato dd/MM/yyyy, con soporte para rango (between) y validacion de formato
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../erp_datepicker.dart';

class DynamicDateField extends StatefulWidget {
  final String label;
  final String? value;
  final String? value2;
  final bool isRange;
  final bool modified;
  final String? errorText;
    final bool enabled;    

  final ValueChanged<String>? onChanged;
  final Function(String, String)? onChangedRange;

  const DynamicDateField({
    super.key,
    required this.label,
    this.value,
    this.value2,
    this.isRange = false,
    this.modified = false,
    this.errorText,
    this.enabled =true,
    this.onChanged,
    this.onChangedRange,
  });

  @override
  State<DynamicDateField> createState() => _DynamicDateFieldState();
}

class _DynamicDateFieldState extends State<DynamicDateField> {
  late TextEditingController c1;
  late TextEditingController c2;
  final DateFormat fmt = DateFormat('dd/MM/yyyy', 'es_CR');

  @override
  void initState() {
    super.initState();
    c1 = TextEditingController(text: _display(widget.value));
    c2 = TextEditingController(text: _display(widget.value2));
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String _display(String? iso) {
    if (iso == null || iso.isEmpty) return "";
    final dt = DateTime.tryParse(iso.replaceFirst("T", " "));
    if (dt == null) return iso;
    return fmt.format(dt);
  }

  DateTime? _parseDMY(String text) {
    if (text.length != 10) return null;
    final d = int.tryParse(text.substring(0, 2));
    final m = int.tryParse(text.substring(3, 5));
    final y = int.tryParse(text.substring(6, 10));
    if (d == null || m == null || y == null) return null;
    return DateTime.tryParse("$y-${_two(m)}-${_two(d)}");
  }

  String _autoFormat(String text) {
    String digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 8) digits = digits.substring(0, 8);

    String formatted = digits;
    if (digits.length >= 3) {
      formatted = digits.substring(0, 2) + "/" + digits.substring(2);
    }
    if (digits.length >= 5) {
      formatted = formatted.substring(0, 5) + "/" + formatted.substring(5);
    }
    return formatted;
  }

Future<DateTime?> _pick(DateTime initial) {
  return showERPDatePickerSingle(
    context: context,
    initialDate: initial,
 //   firstDate: DateTime(1900),
    //lastDate: DateTime(2100),
  );
}
  @override
  Widget build(BuildContext context) {
    return widget.isRange ? _buildRange() : _buildSingle();
  }

Widget _buildSingle() {
  return TextField(
    controller: c1,
    enabled: widget.enabled,                       // ⭐ NUEVO
    style: const TextStyle(fontSize: 13),
    inputFormatters: [
      FilteringTextInputFormatter.allow(RegExp(r'[0-9/]'))
    ],
    decoration: _decoration(widget.label, widget.modified, widget.errorText)
        .copyWith(
      suffixIcon: IconButton(
        icon: const Icon(Icons.calendar_month, size: 18),
        onPressed: widget.enabled                   // ⭐ NUEVO
            ? () async {
                final initial = DateTime.tryParse(widget.value ?? "") ??
                    DateTime.now();
                final picked = await _pick(initial);
                if (picked != null) {
                  final iso = picked.toIso8601String();
                  c1.text = fmt.format(picked);
                  widget.onChanged?.call(iso);
                }
              }
            : null,
      ),
    ),
    onChanged: widget.enabled                       // ⭐ NUEVO
        ? (text) {
            final formatted = _autoFormat(text);
            if (formatted != c1.text) {
              c1.value = TextEditingValue(
                text: formatted,
                selection: TextSelection.collapsed(offset: formatted.length),
              );
            }
            if (formatted.length == 10) {
              final dt = _parseDMY(formatted);
              if (dt != null) widget.onChanged?.call(dt.toIso8601String());
            }
          }
        : (_) {},                                   // ⭐ función vacía
  );
}
  Widget _buildRange() {
  return Row(
    children: [
      Expanded(
        child: TextField(
          controller: c1,
          enabled: widget.enabled,                  // ⭐ NUEVO
          style: const TextStyle(fontSize: 13),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9/]'))
          ],
          decoration: _decoration("Desde", false, null).copyWith(
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_month, size: 18),
              onPressed: widget.enabled              // ⭐ NUEVO
                  ? () async {
                      final initial = DateTime.tryParse(widget.value ?? "") ??
                          DateTime.now();
                      final picked = await _pick(initial);
                      if (picked != null) {
                        final iso = picked.toIso8601String();
                        c1.text = fmt.format(picked);
                        widget.onChangedRange?.call(iso, widget.value2 ?? "");
                      }
                    }
                  : null,
            ),
          ),
          onChanged: widget.enabled                 // ⭐ NUEVO
              ? (text) {
                  final formatted = _autoFormat(text);
                  if (formatted != c1.text) {
                    c1.value = TextEditingValue(
                      text: formatted,
                      selection:
                          TextSelection.collapsed(offset: formatted.length),
                    );
                  }
                  if (formatted.length == 10) {
                    final dt = _parseDMY(formatted);
                    if (dt != null) {
                      widget.onChangedRange?.call(
                          dt.toIso8601String(), widget.value2 ?? "");
                    }
                  }
                }
              : (_) {},
        ),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: TextField(
          controller: c2,
          enabled: widget.enabled,                  // ⭐ NUEVO
          style: const TextStyle(fontSize: 13),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9/]'))
          ],
          decoration: _decoration("Hasta", false, null).copyWith(
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_month, size: 18),
              onPressed: widget.enabled              // ⭐ NUEVO
                  ? () async {
                      final initial =
                          DateTime.tryParse(widget.value2 ?? "") ??
                              DateTime.now();
                      final picked = await _pick(initial);
                      if (picked != null) {
                        final iso = picked.toIso8601String();
                        c2.text = fmt.format(picked);
                        widget.onChangedRange?.call(
                            widget.value ?? "", iso);
                      }
                    }
                  : null,
            ),
          ),
          onChanged: widget.enabled                 // ⭐ NUEVO
              ? (text) {
                  final formatted = _autoFormat(text);
                  if (formatted != c2.text) {
                    c2.value = TextEditingValue(
                      text: formatted,
                      selection:
                          TextSelection.collapsed(offset: formatted.length),
                    );
                  }
                  if (formatted.length == 10) {
                    final dt = _parseDMY(formatted);
                    if (dt != null) {
                      widget.onChangedRange?.call(
                          widget.value ?? "", dt.toIso8601String());
                    }
                  }
                }
              : (_) {},
        ),
      ),
    ],
  );
}
  InputDecoration _decoration(String label, bool modified, String? errorText) {
    return InputDecoration(
      isDense: true,
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13),
      errorText: errorText,
      errorStyle: const TextStyle(fontSize: 11),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
      fillColor: modified ? Colors.orange.shade100 : null,
      filled: modified,
      prefixIcon: modified
          ? const Icon(Icons.warning_amber, color: Colors.orange, size: 18)
          : null,
      prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }
}
