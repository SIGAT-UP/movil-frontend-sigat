import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vigilancia_durazno/data/app_services.dart';
import 'package:vigilancia_durazno/data/local/paquete_campo_store.dart';
import 'package:vigilancia_durazno/data/repositories/field_repositories.dart';

import 'support/backend_de_prueba.dart';

/// Descarga, caché e invalidación del paquete de campo del predio. No se prueba el GeoJSON.
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

  test('descarga el paquete y queda disponible', () async {
    await iniciarSesion();
    expect(await AppServices.maps.isMapDownloaded('1'), isFalse);

    await AppServices.maps.downloadMap('1');

    expect(await AppServices.maps.isMapDownloaded('1'), isTrue);
    final local = await PaqueteCampoStore().leer('1');
    expect(local!.version, 1);
    expect(local.hash, 'a' * 64);
  });

  test('con el mismo hash no vuelve a bajar el contenido', () async {
    await iniciarSesion();
    await AppServices.maps.downloadMap('1');
    prueba.peticiones.clear();

    await AppServices.maps.downloadMap('1');

    expect(prueba.peticiones.where((p) => p.contains('/contenido')), isEmpty);
  });

  test('si cambia el hash, la copia se invalida y se reemplaza', () async {
    await iniciarSesion();
    await AppServices.maps.downloadMap('1');
    prueba.paquetes['1'] =
        BackendDePrueba.paqueteDePrueba(version: 2, hash: 'b' * 64);

    expect(await AppServices.maps.isMapDownloaded('1'), isFalse);
    expect(await PaqueteCampoStore().leer('1'), isNull);

    await AppServices.maps.downloadMap('1');
    final local = await PaqueteCampoStore().leer('1');
    expect(local!.version, 2);
    expect(local.hash, 'b' * 64);
  });

  test('un paquete invalidado en el servidor se descarta', () async {
    await iniciarSesion();
    await AppServices.maps.downloadMap('1');
    prueba.paquetes['1']!['invalidado_en'] = '2026-11-21T08:00:00+00:00';

    expect(await AppServices.maps.isMapDownloaded('1'), isFalse);
  });

  test('sin red con copia guardada sigue disponible', () async {
    await iniciarSesion();
    await AppServices.maps.downloadMap('1');

    prueba.sinRed = true;

    expect(await AppServices.maps.isMapDownloaded('1'), isTrue);
  });

  test('sin red y sin copia no está descargado', () async {
    prueba.sinRed = true;

    expect(await AppServices.maps.isMapDownloaded('1'), isFalse);
  });

  test('sin conexión declarada no llama al servidor', () async {
    AppServices.isOnline.value = false;

    await expectLater(
        AppServices.maps.downloadMap('1'), throwsA(isA<OfflineException>()));
    expect(prueba.peticiones, isEmpty);
  });

  test('304: el dispositivo ya tiene la versión vigente', () async {
    await iniciarSesion();
    await AppServices.maps.downloadMap('1');
    final etiqueta = '"${'a' * 64}"';

    final respuesta = await AppServices.api
        .getCondicional('/predios/1/paquete-campo/contenido', etag: etiqueta);

    expect(respuesta.modificado, isFalse);
    expect(respuesta.cuerpo, isNull);
  });
}
