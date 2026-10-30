import 'package:flutter/animation.dart';

/// Duraciones, curvas e intervalos de las animaciones de entrada de la app.
/// Un solo lugar para ajustar el ritmo: las pantallas no escriben milisegundos.
///
/// Línea de tiempo al abrir la app (≈ 5 s hasta que el login queda quieto):
///
///   0 ms      Splash: el logo entra desde el borde izquierdo (rebote al final)
///   1200 ms   el logo queda solo, quieto, un momento
///   1500 ms   aparece la frase debajo (fundido + leve subida)
///   2200 ms   pausa para leer
///   3400 ms   logo y frase se desvanecen
///   4000 ms   cambio de pantalla: el login aparece con fundido
///             · la cabecera baja desde arriba
///             · la tarjeta blanca sube desde abajo
///             · los campos aparecen uno tras otro, cada 90 ms
class AppMotion {
  AppMotion._();

  // ---------------- Curvas ----------------

  /// Entrada del logo: se pasa un poco del centro y vuelve (rebote suave).
  static const Curve logoIn = Curves.easeOutBack;

  /// Todo lo que entra: arranca rápido y frena al llegar.
  static const Curve enter = Curves.easeOutCubic;

  /// Todo lo que sale: arranca lento y acelera al irse.
  static const Curve exit = Curves.easeInCubic;

  // ---------------- Splash ----------------

  static const Duration splashLogoIn = Duration(milliseconds: 1200);

  /// El logo, ya en el centro, queda solo antes de que aparezca la frase:
  /// primero se ve el logo y DESPUÉS el eslogan, no a la vez.
  static const Duration splashLogoRest = Duration(milliseconds: 300);
  static const Duration splashTaglineIn = Duration(milliseconds: 700);
  static const Duration splashHold = Duration(milliseconds: 1200);
  static const Duration splashExit = Duration(milliseconds: 600);

  static const Duration splashTotal = Duration(
    milliseconds: 1200 + 300 + 700 + 1200 + 600, // logo + reposo + frase + pausa + salida
  );

  // Inicio de cada fase dentro de la splash.
  static const Duration splashTaglineStart = Duration(milliseconds: 1200 + 300);
  static const Duration splashHoldStart = Duration(milliseconds: 1200 + 300 + 700);
  static const Duration splashExitStart = Duration(milliseconds: 1200 + 300 + 700 + 1200);

  /// Cuánto se desplaza la frase al subir, en fracciones de su propio alto.
  static const double taglineRise = 0.6;

  // ---------------- Splash → login ----------------

  /// Fundido entre la splash y el login (PageRouteBuilder).
  static const Duration toLogin = Duration(milliseconds: 650);

  // ---------------- Entrada del login ----------------

  static const Duration loginHeader = Duration(milliseconds: 550);
  static const Duration loginCardStart = Duration(milliseconds: 150);
  static const Duration loginCard = Duration(milliseconds: 550);

  /// Primer elemento de la tarjeta, separación entre elementos y duración de cada uno.
  static const Duration loginItemsStart = Duration(milliseconds: 450);
  static const Duration loginItemStep = Duration(milliseconds: 90);
  static const Duration loginItem = Duration(milliseconds: 380);

  /// Cuánto suben los elementos de la tarjeta al aparecer (fracción de su alto).
  static const double loginItemRise = 0.35;

  /// Duración total de la entrada del login para `count` elementos escalonados.
  static Duration loginTotal(int count) =>
      loginItemsStart + loginItemStep * (count - 1) + loginItem;

  // ---------------- Utilidad ----------------

  /// Fase [start, start + length] expresada como `Interval` dentro de `total`,
  /// para escalonar varias animaciones con UN solo AnimationController.
  static Interval phase(Duration start, Duration length, Duration total, {Curve curve = Curves.linear}) {
    final t = total.inMicroseconds;
    final a = (start.inMicroseconds / t).clamp(0.0, 1.0);
    final b = ((start + length).inMicroseconds / t).clamp(0.0, 1.0);
    return Interval(a, b, curve: curve);
  }
}
