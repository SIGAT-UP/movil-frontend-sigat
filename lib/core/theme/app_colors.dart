import 'package:flutter/material.dart';

/// Paleta institucional ÚNICA. Ninguna pantalla debe escribir `Color(0x...)`:
/// si falta un color, se agrega aquí con un nombre que diga para qué sirve.
class AppColors {
  AppColors._();

  // ---------- Marca ----------
  static const primary = Color(0xFF0B8A4E); // verde principal (botón principal, acentos)
  static const primaryDark = Color(0xFF1E5E3B); // verde secundario (acciones de flujo, títulos de marca)
  static const primaryLight = Color(0xFFE6F4EC); // fondo suave verde (chips, íconos)
  static const primaryDisabled = Color(0xFF5DB88B); // botón principal en estado cargando
  static const successStrong = Color(0xFF17573A); // confirmación sólida ("Lectura guardada")

  // ---------- Navegación (verde de huerto) ----------
  // La navegación es la pieza con identidad propia: un verde profundo, como la
  // sombra bajo los árboles, que deja que el verde de marca sea el de las acciones.
  static const navInk = Color(0xFF10382A); // menú lateral web, etiqueta activa
  static const navInkRaised = Color(0xFF1A4A37); // ítem activo sobre el verde profundo
  static const navOnInk = Color(0xFFFFFFFF); // texto activo sobre el verde profundo
  static const navOnInkMuted = Color(0xFFA8C6B7); // texto inactivo sobre el verde profundo
  static const navOnInkSoft = Color(0xFFE2EEE7); // texto secundario sobre degradados de marca (AA)
  static const navSprout = Color(0xFF7DDBA8); // marca del ítem activo (brote)
  static const navIdle = Color(0xFF5E6763); // íconos inactivos de la barra inferior (contraste al sol)

  // ---------- Fondos y superficies ----------
  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF4F7F5); // fondo de pantallas con tarjetas (gris hoja)
  static const surfaceRaised = Color(0xFFEDF2EF); // botones tonales (atrás), chevrons
  static const surfaceTint = Color(0xFFF3FAF6); // tarjeta resaltada en verde
  static const selectedTint = Color(0xFFF7FCF9); // elemento seleccionado
  static const selectorIdle = Color(0xFFE3EFC9); // círculo de selección sin marcar
  static const border = Color(0xFFDADFDC);
  static const divider = border;

  // ---------- Texto ----------
  static const textPrimary = Color(0xFF1B1F1D);
  static const textSecondary = Color(0xFF6B7370);
  static const textHint = Color(0xFFA3AAA6);

  // ---------- Estados ----------
  static const error = Color(0xFFD32F2F);
  static const errorLight = Color(0xFFFDECEC);
  static const errorBorder = Color(0xFFF2B8B8);

  static const info = Color(0xFF2F6FD3);
  static const infoLight = Color(0xFFEAF2FD);
  static const infoBorder = Color(0xFFC7DBF7);

  static const warning = Color(0xFFC98A00);
  static const warningStrong = Color(0xFFE0A100); // "Pendiente" en leyendas, marcos, íconos
  static const warningText = Color(0xFF8A5A00); // texto sobre fondo ámbar (contraste AA)
  static const warningLight = Color(0xFFFFF6E0);
  static const warningBorder = Color(0xFFF3D79A);

  static const successBorder = Color(0xFFBFE3CE);

  // ---------- Superficies especiales ----------
  static const scannerBackground = Color(0xFF14201A); // fondo de la cámara/escáner
  static const mapPlaceholder = Color(0xFFD5D9D7); // fondo provisional del mapa
  static const mapGrid = Color(0xFFC4C9C6);
  static const mapLabel = Color(0xFF7F8783);
  static const fallbackTop = Color(0xFFDFF0E3); // imagen no disponible
  static const fallbackBottom = Color(0xFFB9DDB0);
  static const heroVeilTop = Color(0xCCFFFFFF); // velo blanco sobre la foto del login
  static const heroVeilMid = Color(0x55FFFFFF);
  static const overlayDark = Color(0x73000000); // botones sobre cámara
}
