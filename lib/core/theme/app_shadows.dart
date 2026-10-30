import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Sombras del sistema. Solo existen tres niveles + la del logo.
class AppShadows {
  AppShadows._();

  /// Tarjetas sobre fondo (casi imperceptible). Teñida de verde profundo en
  /// lugar de negro: sobre el gris hoja se ve más limpia.
  static const card = [
    BoxShadow(color: Color(0x0A10382A), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0D10382A), blurRadius: 12, offset: Offset(0, 4)),
  ];

  /// Barra de navegación inferior: sombra hacia arriba, sin línea divisoria.
  static const nav = [BoxShadow(color: Color(0x1A10382A), blurRadius: 24, offset: Offset(0, -4))];

  /// Elementos flotantes sobre el mapa o la cámara.
  static const floating = [BoxShadow(color: Color(0x26000000), blurRadius: 10, offset: Offset(0, 3))];

  /// Confirmaciones que se elevan sobre el contenido ("Lectura guardada").
  static const raised = [BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 3))];

  /// Brillo verde del ícono de marca.
  static final brand = [
    BoxShadow(color: AppColors.primary.withValues(alpha: .25), blurRadius: 10, offset: const Offset(0, 4)),
  ];
}
