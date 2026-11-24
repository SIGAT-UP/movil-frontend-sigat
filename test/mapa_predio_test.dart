import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vigilancia_durazno/data/app_services.dart';

import 'support/backend_de_prueba.dart';

/// GeoJSON del paquete de campo: se guarda al descargar y queda disponible sin red.
void main() {
  late BackendDePrueba prueba;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    prueba = BackendDePrueba()..conectarApp();
    prueba.paquetes['1'] =
        BackendDePrueba.paqueteDePrueba(version: 1, hash: 'a' * 64);
    AppServices.isOnline.value = true;
  });

  Future<void> iniciarSesion() async {
    final clave = prueba.crearCuenta(
        usuario: 'tec.a', nombre: 'Ana Pérez', rol: 'tecnico', id: 11);
    final r = await AppServices.api.post('/auth/login',
        body: {'usuario': 'tec.a', 'contrasena': clave}, auth: false);
    await AppServices.api.store.saveTokens(
        access: r!['token'] as String, refresh: r['token_refresco'] as String?);
  }

  test('GeoJSON disponible sin red tras descargar', () async {
    await iniciarSesion();
    await AppServices.maps.downloadMap('1');

    prueba.sinRed = true;
    final mapa = await AppServices.maps.getMapaLocal('1');

    expect(mapa, isNotNull);
    expect(mapa!.predio.properties['nombre'], 'Predio de prueba');
    expect(mapa.lotes.features.single.properties['lote_id'], 'L-01');
    expect(mapa.lotes.features.single.geometry!['type'], 'Polygon');
    expect(mapa.trampas.features.single.properties['tram_codigo'], 'ICA-001');
    expect(mapa.celdas.features, isEmpty);
  });

  test('sin paquete descargado no hay GeoJSON', () async {
    expect(await AppServices.maps.getMapaLocal('1'), isNull);
  });

  test('un mapa con forma inválida no se guarda', () async {
    await iniciarSesion();
    prueba.paquetes['1']!['mapa'] = {'lotes': 'no es una colección'};

    await expectLater(
        AppServices.maps.downloadMap('1'), throwsA(isA<TypeError>()));
    expect(await AppServices.maps.getMapaLocal('1'), isNull);
  });
}
