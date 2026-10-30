import 'package:flutter_test/flutter_test.dart';
import 'package:vigilancia_durazno/data/app_services.dart';
import 'package:vigilancia_durazno/data/local/pending_store.dart';
import 'package:vigilancia_durazno/data/models/planning.dart';
import 'package:vigilancia_durazno/data/repositories/field_repositories.dart';

import 'support/backend_de_prueba.dart';

/// Planificaciones: lo que hace el CLIENTE (rutas, cuerpos, validaciones antes de enviar).
/// Las reglas de negocio (solo el destinatario responde, una sola respuesta, aviso al
/// destinatario) las aplica el backend en `/planificaciones…`, que hoy responde 501: la app
/// lo dice y no finge que se guardó.
void main() {
  late BackendDePrueba backend;
  late PendingStore pendientes;

  Planning nueva({PlanningDoc? doc, List<String> lotes = const []}) => Planning(
        id: 'local',
        target: PlanningTarget.tecnico,
        recipientId: '5',
        recipientName: 'Destinatario',
        activity: 'Muestreo',
        lotNames: lotes,
        startDate: DateTime(2026, 11, 3),
        createdAt: DateTime(2026, 10, 29),
        createdByName: 'Agrónomo',
        doc: doc,
      );

  setUp(() async {
    backend = BackendDePrueba();
    final clave = backend.crearCuenta(usuario: 'agro.prueba', nombre: 'Agrónomo Prueba', rol: 'AGRONOMO_SUPERVISOR');
    pendientes = backend.conectarApp();
    AppServices.session.value = await AppServices.auth.login(username: 'agro.prueba', password: clave, remember: false);
  });
  tearDown(() => AppServices.session.value = null);

  test('bandejas: recibidas y creadas piden su filtro al servidor', () async {
    await expectLater(AppServices.plannings.getReceived('1'), throwsA(isA<NotAvailableYet>()));
    await expectLater(AppServices.plannings.getCreated(), throwsA(isA<NotAvailableYet>()));
    expect(backend.peticiones, containsAll(['GET /planificaciones?bandeja=recibidas', 'GET /planificaciones?bandeja=creadas']));
  });

  test('responder va a la ruta del contrato; con 501 se informa y no se finge', () async {
    await expectLater(AppServices.plannings.accept('7'), throwsA(isA<NotAvailableYet>()));
    await expectLater(AppServices.plannings.reject('7', '  Esa semana estoy en cosecha  '), throwsA(isA<NotAvailableYet>()));
    expect(backend.peticiones, containsAll(['POST /planificaciones/7/aceptacion', 'POST /planificaciones/7/rechazo']));
    expect(backend.cuerpos['POST /planificaciones/7/rechazo'], {'motivo': 'Esa semana estoy en cosecha'});
  });

  test('rechazar sin motivo no llega al servidor, ni con espacios', () async {
    for (final motivo in ['', '    ']) {
      await expectLater(AppServices.plannings.reject('7', motivo), throwsA(isA<DataException>()));
    }
    expect(backend.peticiones.where((p) => p.contains('rechazo')), isEmpty);
  });

  test('"no ejecutada" exige justificación antes de enviar', () async {
    await expectLater(
      AppServices.plannings.reportLotResult('7', 'Lote A', executed: false, justification: '  '),
      throwsA(isA<DataException>()),
    );
    expect(backend.peticiones.where((p) => p.contains('/resultado')), isEmpty);
  });

  test('crear: los lotes viajan por su lote_id del servidor', () async {
    backend.respuestasExtra['GET /planificaciones/lotes-asignables'] = [
      {'lote_id': 10, 'lote_codigo': 'A', 'lote_descripcion': 'Lote A', 'pred_id': 1, 'pred_nombre': 'Predio'},
    ];
    final lotes = await AppServices.plannings.getAssignableLots();
    expect(lotes, ['Predio · Lote A']);

    await expectLater(AppServices.plannings.create(nueva(lotes: lotes)), throwsA(isA<NotAvailableYet>()));
    final cuerpo = backend.cuerpos['POST /planificaciones'] as Map<String, dynamic>;
    expect(cuerpo['lote_ids'], [10]);
    expect(cuerpo['usua_id_destinatario'], 5);
    expect(cuerpo['plan_fecha_inicio'], '2026-11-03');
  });

  test('crear con documento: la subida aún no existe, no se envía nada', () async {
    const doc = PlanningDoc(id: 'd', fileName: 'instrucciones.pdf', sizeBytes: 10);
    await expectLater(AppServices.plannings.create(nueva(doc: doc)), throwsA(isA<NotAvailableYet>()));
    expect(backend.peticiones, isNot(contains('POST /planificaciones')));
  });

  test('terminar la visita de un lote deja su resultado PENDIENTE en el teléfono', () async {
    await AppServices.plannings.markLotExecutedForUser('1', 'Lote A');
    final cola = await pendientes.forOwner('1');
    expect(cola.single.kind, PendingKind.resultadoLote);
  });

  test('modelo: la actividad del técnico ya viene autorizada; la planeación del productor se responde', () {
    Planning desde(String rol) => Planning.fromApi({
          'plan_id': 7, 'plan_actividad': 'Muestreo', 'plan_fecha_inicio': '2026-11-22',
          'plan_estado': 'pendiente', 'plan_creada_en': '2026-11-15T10:00:00Z',
          'usua_id_destinatario': 3, 'destinatario': 'Destinatario', 'rol_destinatario': rol,
          'creador': 'Agrónomo', 'lotes': ['A'],
        });
    expect(desde('Técnico').recipientCanRespond, isFalse);
    expect(desde('Productor').recipientCanRespond, isTrue);
    expect(desde('Productor').status.canRespond, isTrue);
  });
}
