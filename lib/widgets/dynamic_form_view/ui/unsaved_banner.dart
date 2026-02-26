import 'package:flutter/material.dart';

class UnsavedChangesBanner extends StatelessWidget {
  const UnsavedChangesBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Colors.orange.shade300,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.15), // ⭐ reemplazo correcto
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber,
            color: Colors.orange,
            size: 18,
          ),
          const SizedBox(width: 6),
          const Text(
            "Hay cambios sin guardar",
            style: TextStyle(
              fontSize: 13,
              color: Colors.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}