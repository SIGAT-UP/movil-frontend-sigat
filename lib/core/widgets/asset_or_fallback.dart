import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Muestra una imagen de assets; si no existe, pinta un degradado con ícono.
/// Así la app corre aunque todavía no hayas copiado las ilustraciones.
class AssetOrFallback extends StatelessWidget {
  const AssetOrFallback(
    this.path, {
    super.key,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.eco,
    this.width,
    this.height,
  });

  final String path;
  final BoxFit fit;
  final IconData fallbackIcon;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.fallbackTop, AppColors.fallbackBottom],
          ),
        ),
        alignment: Alignment.center,
        child: Icon(fallbackIcon, size: 40, color: AppColors.primary.withValues(alpha: .5)),
      ),
    );
  }
}
