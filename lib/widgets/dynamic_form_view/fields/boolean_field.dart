import 'package:flutter/material.dart';

class BooleanField extends StatelessWidget {
  final String label;
  final bool value;
  final bool modified;
  final ValueChanged<bool> onChanged;

  const BooleanField({
    super.key,
    required this.label,
    required this.value,
    required this.modified,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: modified ? Colors.orange.shade100 : null,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: modified ? Colors.orange : Colors.grey.shade400,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: modified ? Colors.orange.shade900 : Colors.black87,
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}