import 'package:flutter/material.dart';

import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

import '../theme/app_colors.dart';

enum AlertType { error, info, success, warning }

/// Caja de aviso con título y mensaje (error de login, "Verás solo lo de tu rol", etc.).
class AlertBanner extends StatelessWidget {
  const AlertBanner({super.key, required this.title, this.message, this.type = AlertType.error});

  final String title;
  final String? message;
  final AlertType type;

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg, icon) = switch (type) {
      AlertType.error => (AppColors.errorLight, AppColors.errorBorder, AppColors.error, Icons.warning_amber_rounded),
      AlertType.info => (AppColors.infoLight, AppColors.infoBorder, AppColors.info, Icons.info_outline),
      AlertType.success => (AppColors.primaryLight, AppColors.successBorder, AppColors.primaryDark, Icons.check_circle_outline),
      AlertType.warning => (AppColors.warningLight, AppColors.warningBorder, AppColors.warningText, Icons.warning_amber_rounded),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.bodySmStrong.copyWith(
                    color: (type == AlertType.error || type == AlertType.warning) ? AppColors.textPrimary : fg,
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 2),
                  Text(message!, style: AppText.caption.copyWith(color: fg.withValues(alpha: .85))),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
