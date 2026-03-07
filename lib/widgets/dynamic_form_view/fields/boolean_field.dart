import 'package:flutter/material.dart';

class BooleanField extends StatelessWidget {
  final String label;
  final bool value;
  final bool modified;
  final ValueChanged<bool> onChanged;
   final bool enabled;  

  const BooleanField({
    super.key,
    required this.label,
    required this.value,
    required this.modified,
    this.enabled = true, // Valor por defecto para enabled
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: modified ? Colors.orange.shade100 : null,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: modified ? Colors.orange : Colors.grey.shade400,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // ⭐ label alineado a la izquierda
        children: [
          // ⭐ Label arriba
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: modified ? Colors.orange.shade900 : Colors.black87,
            ),
          ),

          const SizedBox(height: 4),

          // ⭐ Switch debajo del label
          Transform.scale(
            scale: 0.75,
            child: Switch(
              value: value,
              onChanged: enabled ? onChanged : null, // Deshabilita el switch si enabled es false
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}