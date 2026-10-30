import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Chip de estado de conexión: "Conectado", "En línea", "Sin conexión".
class ConnectionChip extends StatelessWidget {
  const ConnectionChip({super.key, required this.isOnline, this.onlineLabel = 'Conectado', this.dense = false});

  final bool isOnline;
  final String onlineLabel;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final color = isOnline ? AppColors.primaryDark : AppColors.textSecondary;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 6 : 10, vertical: dense ? 2 : 4),
      decoration: BoxDecoration(
        color: isOnline ? AppColors.primaryLight : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: isOnline ? AppColors.successBorder : AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOnline ? (dense ? Icons.check_circle : Icons.wifi) : Icons.wifi_off,
            size: dense ? 10 : 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            isOnline ? onlineLabel : 'Sin conexión',
            style: AppText.caption.copyWith(fontSize: dense ? 9 : 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

/// Etiqueta pequeña tipo píldora (ej. "Vigilancia fitosanitaria · Cultivo de durazno").
class TagPill extends StatelessWidget {
  const TagPill(this.text, {super.key, this.background = AppColors.primaryLight});

  final String text;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
      child: Text(
        text,
        style: AppText.micro.copyWith(fontWeight: FontWeight.w700, color: AppColors.primaryDark),
      ),
    );
  }
}
