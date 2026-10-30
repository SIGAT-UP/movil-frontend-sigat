import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Indicador de carga centrado (pantallas o bloques que esperan datos).
class AppLoader extends StatelessWidget {
  const AppLoader({super.key, this.padding = EdgeInsets.zero});
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
}

/// Indicador de carga en línea con texto ("Validando credenciales...").
class AppInlineLoader extends StatelessWidget {
  const AppInlineLoader({super.key, this.label, this.color = AppColors.info, this.size = 12});
  final String? label;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: size, height: size, child: CircularProgressIndicator(strokeWidth: 1.8, color: color)),
          if (label != null) ...[const SizedBox(width: 6), Text(label!, style: AppText.caption)],
        ],
      );
}

/// Barra de confirmación sólida que reemplaza un botón tras guardar
/// ("Lectura guardada", "Aplicación registrada correctamente.").
class SuccessToastBar extends StatelessWidget {
  const SuccessToastBar(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        height: AppSpacing.buttonHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.successStrong,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          boxShadow: AppShadows.raised,
        ),
        child: Row(
          children: [
            const Icon(Icons.check, color: Colors.white, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(message, style: AppText.button.copyWith(color: Colors.white), overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

/// Encabezado de resultado exitoso con check grande
/// ("Cosecha registrada", "Registros sincronizados").
class SuccessHero extends StatelessWidget {
  const SuccessHero({super.key, required this.title, this.message, this.icon = Icons.check});
  final String title;
  final String? message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.successBorder, width: 2),
          ),
          child: Icon(icon, size: 34, color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(title, textAlign: TextAlign.center, style: AppText.h2),
        if (message != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(message!, textAlign: TextAlign.center, style: AppText.secondary),
        ],
      ],
    );
  }
}
