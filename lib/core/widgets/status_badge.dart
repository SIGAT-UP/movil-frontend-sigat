import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Tono visual de un estado. Lo usan badges, filas de checklist y tarjetas.
enum StatusTone { success, warning, error, info, neutral }

extension StatusToneColors on StatusTone {
  Color get fg => switch (this) {
        StatusTone.success => AppColors.primaryDark,
        StatusTone.warning => AppColors.warningText,
        StatusTone.error => AppColors.error,
        StatusTone.info => AppColors.info,
        StatusTone.neutral => AppColors.textSecondary,
      };

  Color get bg => switch (this) {
        StatusTone.success => AppColors.primaryLight,
        StatusTone.warning => AppColors.warningLight,
        StatusTone.error => AppColors.errorLight,
        StatusTone.info => AppColors.infoLight,
        StatusTone.neutral => AppColors.surface,
      };

  Color get border => switch (this) {
        StatusTone.success => AppColors.successBorder,
        StatusTone.warning => AppColors.warningBorder,
        StatusTone.error => AppColors.errorBorder,
        StatusTone.info => AppColors.infoBorder,
        StatusTone.neutral => AppColors.border,
      };
}

/// Píldora de estado: "Pendiente", "Activa", "Identificada", "Sincronizado", "En progreso"...
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.label, {super.key, this.tone = StatusTone.success, this.icon});

  final String label;
  final StatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tone.bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: tone.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 11, color: tone.fg), const SizedBox(width: 3)],
          Text(label, style: AppText.micro.copyWith(fontWeight: FontWeight.w700, color: tone.fg)),
        ],
      ),
    );
  }
}
