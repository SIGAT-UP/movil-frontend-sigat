import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vigilancia_durazno/data/app_services.dart';
import 'package:vigilancia_durazno/data/repositories/field_repositories.dart';

import 'support/backend_de_prueba.dart';

/// Detalle de visita y resumen del lote: lectura desde el servidor y respaldo sin red.
void main() {
  late BackendDePrueba prueba;

  final visita = {
    'visi_id': 'v-1',
    'usua_id': 11,
    'tecnico': 'Ana Pérez',
    'pred_id': 1,
    'pred_nombre': 'Finca La Esperanza',
    'ruta_id': null,
    't_inicio_obs': '2026-11-20T14:00:00+00:00',
    't_fin_obs': '2026-11-20T15:00:00+00:00',
    't_captura': '2026-11-20T15:00:00+00:00',
    't_sincronizacion': '2026-11-20T15:01:00+00:00',
    'deriva_reloj_seg': null,
    'estado_revision': 'pendiente',
    'motivo_revision': null,
    'revisada_por': null,
    'revisada_en': null,
    'lote_ids': [1, 2],
    'lotes': ['L-01', 'L-02'],
    'trampas_leidas': 6,
    'lecturas': <Object>[],
  };

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    prueba = BackendDePrueba()..conectarApp();
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

  test('detalle del servidor: predio, lotes y estado de revisión', () async {
    await iniciarSesion();
    prueba.respuestasExtra['GET /visitas/v-1'] = visita;

    final v = await AppServices.history.getVisit('v-1');

    expect(v.predioNombre, 'Finca La Esperanza');
    expect(v.lotes, ['L-01', 'L-02']);
    expect(v.estadoRevision, 'pendiente');
    expect(v.trampasLeidas, 6);
    expect(v.cachedAt, isNull);
  });

  test('sin red muestra la copia guardada con su fecha', () async {
    await iniciarSesion();
    prueba.respuestasExtra['GET /visitas/v-1'] = visita;
    await AppServices.history.getVisit('v-1');

    prueba.sinRed = true;
    final v = await AppServices.history.getVisit('v-1');

    expect(v.lotes, ['L-01', 'L-02']);
    expect(v.cachedAt, isNotNull);
  });

  test('sin red y sin copia: error claro, nunca datos inventados', () async {
    await iniciarSesion();
    prueba.sinRed = true;

    await expectLater(
        AppServices.history.getVisit('v-9'), throwsA(isA<OfflineException>()));
  });

  test('resumen del lote: sin red usa la última copia', () async {
    await iniciarSesion();
    prueba.respuestasExtra['GET /lotes/L-01/resumen'] = {
      'lote_id': 'L-01',
      'lote_descripcion': 'Lote 1',
      'escenario': 'Supresión',
      'mtd': 0.8,
      'trampas_vigentes': 4,
    };
    final vivo = await AppServices.agronomist.getLotSummary('L-01');
    expect(vivo.lotName, 'Lote 1');
    expect(vivo.cachedAt, isNull);

    prueba.sinRed = true;
    final copia = await AppServices.agronomist.getLotSummary('L-01');
    expect(copia.lotName, 'Lote 1');
    expect(copia.cachedAt, isNotNull);
  });
}
