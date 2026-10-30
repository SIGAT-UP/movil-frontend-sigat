import 'package:flutter/foundation.dart';

/// Registro de errores para desarrollo.
///
/// SEGURIDAD: en una compilación de producción (`flutter build --release`) no
/// escribe nada. Así los detalles técnicos y los datos del usuario no quedan
/// en el registro del dispositivo, donde otra app o quien tenga el teléfono
/// podría leerlos.
///
/// Nunca se debe pasar aquí una contraseña ni un token.
class AppLog {
  AppLog._();

  static void error(String where, Object error, [StackTrace? stack]) {
    if (!kDebugMode) return;
    debugPrint('[$where] $error');
    if (stack != null) debugPrint(stack.toString());
  }
}
