import 'package:flutter_test/flutter_test.dart';
import 'package:vigilancia_durazno/core/config/api_config.dart';

/// S-07: una compilación de producción solo se conecta por HTTPS a una URL definida al compilar.
void main() {
  test('en desarrollo (debug/profile) no hay restricción', () {
    expect(ApiConfig.problemaUrl('', release: false), isNull);
    expect(ApiConfig.problemaUrl('http://10.0.2.2:8000/api/v1', release: false), isNull);
  });

  test('en producción exige API_URL', () {
    expect(ApiConfig.problemaUrl('', release: true), contains('API_URL'));
    expect(ApiConfig.problemaUrl('   ', release: true), contains('API_URL'));
  });

  test('en producción rechaza HTTP y URLs sin servidor', () {
    expect(ApiConfig.problemaUrl('http://api.ejemplo.org/api/v1', release: true), contains('HTTPS'));
    expect(ApiConfig.problemaUrl('http://10.0.2.2:8000/api/v1', release: true), contains('HTTPS'));
    expect(ApiConfig.problemaUrl('https:///api/v1', release: true), contains('HTTPS'));
  });

  test('en producción acepta HTTPS', () {
    expect(ApiConfig.problemaUrl('https://api.ejemplo.org/api/v1', release: true), isNull);
  });

  test('las pruebas corren en modo debug: la configuración actual no se bloquea', () {
    expect(ApiConfig.problemaDeConfiguracion, isNull);
  });
}
