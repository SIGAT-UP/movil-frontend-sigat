/// Espaciados, radios y tamaños comunes.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Margen lateral de las pantallas móviles.
  static const double screenH = 20;

  /// Margen de contenido en web / pantallas anchas.
  static const double screenWide = 32;

  /// Ancho máximo de formularios y contenido en web, para que no se estiren.
  static const double maxContentWidth = 720;

  // Radios
  static const double radiusSm = 10; // campos, botones
  static const double radiusMd = 14; // tarjetas
  static const double radiusLg = 20; // hojas y paneles
  static const double radiusXl = 24; // panel inferior de la cámara, hojas inferiores
  static const double radiusPill = 100; // chips, badges

  // Alturas táctiles (mínimo 48 en móvil)
  static const double fieldHeight = 48;
  static const double buttonHeight = 52; // campo: se usa con guantes

  /// A partir de este ancho se usa navegación lateral (web / tablet).
  static const double wideBreakpoint = 840;
}

/// Tamaños de ícono del sistema.
class AppIconSize {
  AppIconSize._();
  static const double xs = 13; // dentro de chips y badges
  static const double sm = 16;
  static const double md = 20; // por defecto en campos y botones
  static const double lg = 24;
  static const double xl = 32;
  static const double hero = 40;
}
