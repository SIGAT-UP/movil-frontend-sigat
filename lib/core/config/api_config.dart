import 'package:flutter/foundation.dart';

/// Dónde está el backend `sigat-durazno-api` (el mismo de la web). Se fija al compilar:
///
///   flutter run --dart-define=API_URL=http://10.0.2.2:8000/api/v1
///   flutter build apk --release --dart-define=API_URL=https://api.su-dominio.org/api/v1
///
/// Sin `API_URL`, en DESARROLLO (debug/profile) se usa el backend local: en el emulador de
/// Android la máquina anfitriona es `10.0.2.2`; en web y escritorio, `localhost`.
///
/// SEGURIDAD (S-07): una compilación de PRODUCCIÓN (`--release`) exige `API_URL` con HTTPS.
/// Si falta o usa HTTP, la app no se conecta a nada y muestra una pantalla de configuración
/// inválida ([problemaDeConfiguracion], usada en `main.dart`). Así ninguna dirección de
/// desarrollo queda activa por accidente en una versión publicada.
class ApiConfig {
  ApiConfig._();

  static const _definida = String.fromEnvironment('API_URL');

  static String get baseUrl {
    final url = _definida.isNotEmpty
        ? _definida
        : (!kIsWeb && defaultTargetPlatform == TargetPlatform.android
            ? 'http://10.0.2.2:8000/api/v1'
            : 'http://localhost:8000/api/v1');
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  /// Motivo por el que esta compilación no debe conectarse al backend, o null si todo está bien.
  static String? get problemaDeConfiguracion => problemaUrl(_definida, release: kReleaseMode);

  /// Regla de [problemaDeConfiguracion], separada para poder probarla.
  @visibleForTesting
  static String? problemaUrl(String definida, {required bool release}) {
    if (!release) return null;
    if (definida.trim().isEmpty) {
      return 'Esta versión se compiló sin la dirección del servidor (API_URL). '
          'Compile con --dart-define=API_URL=https://…/api/v1.';
    }
    final u = Uri.tryParse(definida.trim());
    if (u == null || u.scheme != 'https' || u.host.isEmpty) {
      return 'La dirección del servidor debe usar HTTPS en una versión de producción.';
    }
    return null;
  }

  /// Tiempo máximo de espera por petición.
  static const timeout = Duration(seconds: 20);

  /// Versión que se informa al backend (cabecera X-App-Version y registro del dispositivo).
  /// Mantenerla igual a `version` de pubspec.yaml, o pasarla con --dart-define=APP_VERSION=...
  static const appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');
}
