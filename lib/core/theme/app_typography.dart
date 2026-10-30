import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Escala tipográfica única. Usar `style: AppText.caption` en vez de escribir TextStyle.
/// Para variar color/peso puntual: `AppText.body.copyWith(color: ...)`.
class AppText {
  AppText._();

  // Títulos
  static const display = TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1.15, letterSpacing: -0.4, color: AppColors.textPrimary); // cifras grandes
  static const h1 = TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1.2, letterSpacing: -0.3, color: AppColors.textPrimary); // titular de pantalla
  static const h2 = TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.25, letterSpacing: -0.2, color: AppColors.textPrimary); // título de bloque / tarjeta grande
  static const h3 = TextStyle(fontSize: 16, fontWeight: FontWeight.w800, height: 1.3, letterSpacing: -0.1, color: AppColors.textPrimary); // título de sección
  static const title = TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary); // título de ítem de lista

  // Cuerpo
  static const body = TextStyle(fontSize: 14, height: 1.45, color: AppColors.textPrimary);
  static const label = TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary);
  static const bodySm = TextStyle(fontSize: 12, color: AppColors.textPrimary);
  static const bodySmStrong = TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary);
  static const secondary = TextStyle(fontSize: 12, color: AppColors.textSecondary);

  // Apoyo
  static const caption = TextStyle(fontSize: 11, color: AppColors.textSecondary);
  static const micro = TextStyle(fontSize: 10, color: AppColors.textSecondary);
  static const overline = TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary); // "Validación", "Resumen"
  static const button = TextStyle(fontSize: 14, fontWeight: FontWeight.w700);
  static const link = TextStyle(fontSize: 12, fontWeight: FontWeight.w600);

  // Sobre fondos oscuros (cámara / escáner)
  static const onDarkTitle = TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white);
  static const onDarkBody = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white);
  static const onDarkMuted = TextStyle(fontSize: 12, color: Colors.white70);

  // Marca
  static const brandHeadline =
      TextStyle(fontSize: 18, height: 1.05, fontWeight: FontWeight.w800, color: AppColors.primaryDark);
}
