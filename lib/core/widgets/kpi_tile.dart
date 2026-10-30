import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Indicador breve: una cifra con su etiqueta.
/// Se usa en el resumen fitosanitario del Agrónomo.
/// Cuando no hay dato, se muestra "Sin registrar" en gris.
class KpiTile extends StatelessWidget {
  const KpiTile({super.key, required this.label, required this.value, this.hint, this.icon});

  final String label;

  /// null = sin dato disponible.
  final String? value;
  final String? hint;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final sinDato = value == null || value!.isEmpty;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
              ],
              Expanded(child: Text(label, style: AppText.micro)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            sinDato ? 'Sin registrar' : value!,
            style: sinDato
                ? AppText.bodySm.copyWith(color: AppColors.textHint)
                : AppText.h3.copyWith(fontSize: 17),
          ),
          if (hint != null) Text(hint!, style: AppText.micro),
        ],
      ),
    );
  }
}
