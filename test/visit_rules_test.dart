import 'package:flutter_test/flutter_test.dart';
import 'package:vigilancia_durazno/data/app_services.dart';
import 'package:vigilancia_durazno/data/local/pending_store.dart';
import 'package:vigilancia_durazno/data/models/reading.dart';
import 'package:vigilancia_durazno/features/visit/visit_controller.dart';

import 'support/backend_de_prueba.dart';

/// La visita del técnico cuenta SOLO lo que se registra en ella, y lo registrado queda
/// en el TELÉFONO como pendiente de enviar (el servidor aún no recibe sincronizaciones).
///
/// `GET /lotes/{id}` y `GET /trampas` todavía responden 501 en el backend real; aquí el
/// doble del backend devuelve filas con la forma del contrato (`Lote`, `Trampa`) SOLO para
/// probar la lógica de la visita en el cliente.
void main() {
  final visita = VisitController.instance;
  late BackendDePrueba backend;
  late PendingStore pendientes;

  setUp(() async {
    visita.reset();
    backend = BackendDePrueba();

    final clave = backend.crearCuenta(
      usuario: 'tec.prueba',
      nombre: 'Tecnico Prueba',
      rol: 'TECNICO',
      id: 5,
    );

    pendientes = backend.conectarApp();

    // Datos simulados para las pruebas de lotes y trampas.
    backend.respuestasExtra['GET /lotes/10'] = {
      'lote_id': 10,
      'lote_codigo': 'A',
      'lote_descripcion': 'Lote A',
      'lote_area': 1.2,
      'pred_id': 1,
      'pred_nombre': 'Predio de prueba',
      'productor': 'Productor de prueba',
      'municipio': 'Pamplona',
      'cultivo': 'Durazno',
      'vigilancia_activa': true,
      'trampas_vigentes': 2,
    };

    backend.respuestasExtra['GET /trampas'] = [
      for (final n in [1, 3])
        {
          'tram_id': n,
          'tram_codigo': '54518-602-$n',
          'tipo': 'Jackson',
          'lote_id': 10,
          'latitud': 7.37,
          'longitud': -72.64,
          'estado': 'activo',
        },
    ];

    // Autenticación real contra el backend simulado.
    AppServices.session.value = await AppServices.auth.login(
      username: 'tec.prueba',
      password: clave,
      remember: false,
    );
  });
  tearDown(() => AppServices.session.value = null);

  test('Una visita nueva empieza con todas las trampas pendientes', () async {
    final lote = await AppServices.lots.getLot('10');
    await visita.startLot(lote);

    expect(visita.activeTraps, hasLength(2));
    expect(visita.registeredCount, 0);
    expect(visita.pendingCount, visita.activeTraps.length);
    expect(visita.nextTrap?.id, visita.activeTraps.first.id);
    expect(visita.canFinishLot, isFalse);
    expect(visita.readingsThisVisit, 0);
  });

  test('La lectura queda en el teléfono como pendiente y se respeta al volver al lote', () async {
    final lote = await AppServices.lots.getLot('10');
    await visita.startLot(lote);
    final primera = visita.activeTraps.first;

    await visita.saveReading(Reading(
      id: 'r-prueba',
      trapId: primera.id,
      trapLabel: primera.label,
      lotId: lote.id,
      observedAt: DateTime.now(),
      specimens: 2,
      condition: TrapCondition.buenEstado,
    ));
    expect(visita.registeredCount, 1);

    // Guardada en la cola local, NO marcada como enviada.
    final cola = await pendientes.forOwner('5');
    expect(cola.map((p) => p.kind), contains(PendingKind.lectura));
    final lecturas = await AppServices.readings.readingsForLot('10');
    expect(lecturas.single.synced, isFalse);
    expect(lecturas.single.specimens, 2);

    // Sale del lote y vuelve a entrar en la MISMA visita.
    await visita.startLot(lote);
    expect(visita.registeredCount, 1);
    expect(visita.nextTrap?.id, isNot(primera.id));
    expect(visita.readingsThisVisit, 1);
  });

  test('Al cerrar sesión se olvida el avance de la visita (lo guardado sigue en el teléfono)', () async {
    final lote = await AppServices.lots.getLot('10');
    await visita.startLot(lote);
    final t = visita.activeTraps.first;
    await visita.justifyTrap(t, 'Trampa caída por el viento');
    expect(visita.handledCount, 1);

    visita.reset();
    await visita.startLot(lote);
    expect(visita.handledCount, 0);
    expect(await pendientes.forOwner('5'), isNotEmpty);
  });
}