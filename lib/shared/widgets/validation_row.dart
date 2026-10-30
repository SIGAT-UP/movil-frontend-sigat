import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';

/// Fila de validación de trampa (alerta de incoherencia): ✔ cumple, ✖ no cumple, vacío = sin verificar.
class ValidationRow extends StatelessWidget {
  const ValidationRow({super.key, required this.ok, required this.label, this.pendingHint});
  final bool? ok;
  final String label;
  final String? pendingHint;

  @override
  Widget build(BuildContext context) {
    final (Color color, IconData? icon) = switch (ok) {
      true => (AppColors.primary, Icons.check),
      false => (AppColors.error, Icons.close),
      null => (AppColors.border, null),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ok == null ? AppColors.surface : color.withValues(alpha: .12),
              border: Border.all(color: color),
            ),
            child: icon == null ? null : Icon(icon, size: 13, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppText.bodySm),
                if (ok == null && pendingHint != null)
                  Text(pendingHint!, style: AppText.micro),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
