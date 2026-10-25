/// Configuración de la API por entorno.
///
/// Se define en el build, no en el código:
///   flutter run  --dart-define=API_BASE_URL=http://10.0.2.2:8000
///   flutter build apk --dart-define=API_BASE_URL=https://api.tudominio.com
///
/// 10.0.2.2 es el host del equipo visto desde el emulador de Android.
class ApiConfig {
  const ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static String get apiV1 => '$baseUrl/api/v1';
}
