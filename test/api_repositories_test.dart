import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vigilancia_durazno/app/routes.dart';
import 'package:vigilancia_durazno/core/config/api_config.dart';
import 'package:vigilancia_durazno/core/utils/canonical_json.dart';
import 'package:vigilancia_durazno/data/app_services.dart';
import 'package:vigilancia_durazno/data/local/pending_store.dart';
import 'package:vigilancia_durazno/data/models/producer.dart';
import 'package:vigilancia_durazno/data/models/reading.dart';
import 'package:vigilancia_durazno/data/models/user_profile.dart';
import 'package:vigilancia_durazno/data/models/visit.dart';
import 'package:vigilancia_durazno/data/repositories/field_repositories.dart';
import 'package:vigilancia_durazno/data/repositories/profile_repository.dart';

import 'support/backend_de_prueba.dart';

/// Repositorios REALES (`api_repositories.dart`) contra el doble del backend:
/// endpoints que funcionan, endpoints que aún no existen (501) y servidor sin red.
void main() {
  late BackendDePrueba backend;
  late PendingStore pendientes;
  late String yo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    backend = BackendDePrueba();
    final clave = backend.crearCuenta(
        usuario: 'tec.prueba', nombre: 'Técnico Prueba', rol: 'TECNICO', id: 5);
    pendientes = backend.conectarApp();
    AppServices.isOnline.value = true;
    AppServices.session.value = await AppServices.auth
        .login(username: 'tec.prueba', password: clave, remember: false);
    yo = AppServices.session.value!.userId;
  });
  tearDown(() {
    AppServices.session.value = null;
    AppServices.isOnline.value = true;
  });

  group('Configuración por entorno', () {
    test(
        'sin --dart-define la URL es la del backend local (/api/v1, sin barra final)',
        () {
      expect(ApiConfig.baseUrl, endsWith('/api/v1'));
      expect(ApiConfig.baseUrl.endsWith('/'), isFalse);
    });
  });

  group('Avisos (endpoint real)', () {
    test('lista, cuenta y marca como leído con las rutas /yo/notificaciones',
        () async {
      backend.agregarAviso(
        usuaId: 5,
        titulo: 'Nueva actividad',
        categoria: 'asignacion',
        destino: {'ruta': '/planificaciones/9', 'argumento': '9'},
      );
      backend.agregarAviso(usuaId: 99, titulo: 'De otra persona');

      final avisos = await AppServices.notifications.getForUser(yo);
      expect(avisos.map((a) => a.title), ['Nueva actividad']);
      expect(avisos.single.category, NotificationCategory.asignacion);
      expect(avisos.single.target?.route, AppRoutes.planningDetail);
      expect(avisos.single.target?.argument, '9');
      expect(await AppServices.notifications.unreadCount(yo), 1);

      await AppServices.notifications.markAsRead(yo, avisos.single.id);
      expect(await AppServices.notifications.unreadCount(yo), 0);
    });

    test(
        'un destino que la app no tiene (pantalla de la web) se muestra sin abrir nada',
        () async {
      backend.agregarAviso(
        usuaId: 5,
        titulo: 'Solicitud de nueva contraseña',
        categoria: 'solicitudes_cuenta',
        destino: {'ruta': '/admin/usuarios', 'argumento': '3'},
      );
      final aviso = (await AppServices.notifications.getForUser(yo)).single;
      expect(aviso.category, NotificationCategory.solicitudesCuenta);
      expect(aviso.target, isNull);
    });
  });

  group('Inicio y perfil (endpoints reales)', () {
    test('el inicio no inventa conteos que el servidor aún no envía', () async {
      final r = await AppServices.home.getSummary(yo);
      expect(r.assignedLots, isNull);
      expect(r.pendingVisits, isNull);
      expect(r.lastSync, isNull);
    });

    test('el perfil sale de GET /yo/perfil', () async {
      final p = await AppServices.profile.getProfile(yo);
      expect(p.userId, '5');
      expect(backend.peticiones, contains('GET /yo/perfil'));
    });
  });

  group('Endpoint que aún no existe (501) y servidor sin red', () {
    test('lotes: 501 → «todavía no está disponible», nunca una lista inventada',
        () async {
      await expectLater(
        AppServices.lots.getAssignedLots(yo),
        throwsA(isA<NotAvailableYet>()
            .having((e) => e.message, 'mensaje', contains('servidor'))),
      );
    });

    test('sin red → OfflineException con mensaje para la persona', () async {
      backend.sinRed = true;
      await expectLater(AppServices.notifications.getForUser(yo),
          throwsA(isA<OfflineException>()));
      await expectLater(AppServices.lots.getAssignedLots(yo),
          throwsA(isA<OfflineException>()));
    });

    test(
        'foto de perfil y preferencias: el servidor aún no las recibe y se dice',
        () async {
      await expectLater(
        AppServices.profile.updateNotifications(
            yo, const NotificationPreferences(enabled: false)),
        throwsA(isA<BackendNotAvailable>()),
      );
    });
  });

  group('Trabajo sin conexión: pendientes en el teléfono', () {
    Reading lectura() => Reading(
          id: 'lect-1',
          trapId: '3',
          trapLabel: 'ICA-003',
          lotId: '10',
          observedAt: DateTime(2026, 10, 29, 9),
          specimens: 4,
          condition: TrapCondition.buenEstado,
        );

    test('la lectura se guarda local y queda pendiente (synced = false)',
        () async {
      await AppServices.readings.saveReading(lectura());
      final local = await AppServices.readings.readingsForLot('10');
      expect(local.single.specimens, 4);
      expect(local.single.synced, isFalse);
      final cola = await AppServices.sync.getPending();
      expect(cola.single.synced, isFalse);
      expect(cola.single.label, contains('ICA-003'));
    });

    test(
        'autorreportes del productor: si el historial del servidor no está, se ven los locales como pendientes',
        () async {
      await AppServices.producer.saveApplication(PhytoApplication(
        id: 'apli-1',
        date: DateTime(2026, 10, 28),
        product: 'Producto X',
        doseMlPerLiter: 2,
        areaHa: 1,
        responsible: 'Responsable',
      ));
      final actividad = await AppServices.producer.getActivity(yo);
      expect(actividad.single.subtitle, contains('pendiente de enviar'));
      expect(backend.peticiones, contains('GET /actividad'));
    });

    test(
        'sin nada local y sin servidor, el historial muestra el error (no una lista vacía engañosa)',
        () async {
      await expectLater(
          AppServices.history.getVisits(), throwsA(isA<NotAvailableYet>()));
      await AppServices.history.saveVisit(
        VisitRecord(
            id: 'v1',
            date: DateTime(2026, 10, 29),
            lotsDone: 1,
            lotsTotal: 2,
            status: VisitStatus.completada),
      );
      final visitas = await AppServices.history.getVisits();
      expect(visitas.single.status.label, contains('pendiente de enviar'));
    });

    test('cada usuario solo ve sus pendientes', () async {
      await AppServices.readings.saveReading(lectura());
      expect(await pendientes.forOwner(yo), hasLength(1));
      expect(await pendientes.forOwner('otro'), isEmpty);
    });
  });

  group('Sincronización del técnico (Sprint 2)', () {
    const visiId = '11111111-1111-4111-8111-111111111111';
    final inicio = DateTime(2026, 10, 29, 8, 55);

    Reading lectura({String? visita}) => Reading(
          id: 'lect-1',
          trapId: '3',
          trapLabel: 'ICA-003',
          lotId: '10',
          observedAt: DateTime(2026, 10, 29, 9),
          specimens: 4,
          condition: TrapCondition.buenEstado,
          visitId: visita,
        );

    Future<void> encolarVisitaYLectura() async {
      await AppServices.readings.saveFieldVisit(
        visiId: visiId,
        predioId: '2',
        lotId: '10',
        startedAt: inicio,
        label: 'Finca El Mirador · Lote 10',
      );
      await AppServices.readings.saveReading(lectura(visita: visiId));
    }

    test('sube la visita antes que sus lecturas y vacía la cola', () async {
      await encolarVisitaYLectura();
      expect(await AppServices.sync.getPending(), hasLength(2));

      final resumen = await AppServices.sync.push();

      expect(resumen.confirmadas, 2);
      expect(resumen.enRevision, 0);
      expect(resumen.rechazadas, 0);
      expect(resumen.diferidas, 0);
      expect(await AppServices.sync.getPending(), isEmpty);
      expect(backend.registrosAplicados, hasLength(2));
      expect(backend.registrosAplicados.first, visiId);
      expect(
        backend.operacionesRecibidas.map((o) => o['entidad']).toList(),
        ['visita', 'lectura_trampa'],
      );
      expect(await AppServices.sync.lastSync(), isNotNull);
    });

    test('la huella enviada es sha256 del JSON canónico del sobre', () async {
      await encolarVisitaYLectura();
      await AppServices.sync.push();

      for (final op in backend.operacionesRecibidas) {
        final contenido = <String, dynamic>{
          'entidad': op['entidad'],
          'accion': op['accion'],
          'registro_id': op['registro_id'],
          'version': op['version'],
          'linaje': op['linaje'],
          't_observacion': CanonicalJson.instanteCanonico(
              DateTime.parse(op['t_observacion'] as String)),
          'datos': op['datos'],
        };
        expect(CanonicalJson.sha256Hex(contenido), op['hash_contenido'],
            reason: 'huella de ${op['entidad']}');
      }
    });

    test('una lectura sin visita no se envía y dice por qué', () async {
      await AppServices.readings.saveReading(lectura());

      final resumen = await AppServices.sync.push();

      expect(resumen.diferidas, 1);
      expect(resumen.confirmadas, 0);
      expect(backend.operacionesRecibidas, isEmpty);
      final sigue = (await AppServices.sync.getPending()).single;
      expect(sigue.lastError, contains('visita'));
    });

    test('reenviar la misma visita es idempotente (no duplica)', () async {
      await AppServices.readings.saveFieldVisit(
        visiId: visiId,
        predioId: '2',
        lotId: '10',
        startedAt: inicio,
        label: 'Finca El Mirador · Lote 10',
      );
      expect((await AppServices.sync.push()).confirmadas, 1);

      await AppServices.readings.saveFieldVisit(
        visiId: visiId,
        predioId: '2',
        lotId: '10',
        startedAt: inicio,
        label: 'Finca El Mirador · Lote 10',
      );
      final segundo = await AppServices.sync.push();

      expect(segundo.confirmadas, 1);
      expect(backend.operacionesRecibidas, hasLength(2));
      expect(backend.operacionesRecibidas.last['cliente_id'],
          backend.operacionesRecibidas.first['cliente_id']);
      expect(backend.registrosAplicados, hasLength(1));
    });

    test('una operación en «revisar» se conserva y aparece en la bandeja',
        () async {
      backend.porRevisar[visiId] = 'La hora del dispositivo no coincide.';
      await AppServices.readings.saveFieldVisit(
        visiId: visiId,
        predioId: '2',
        lotId: '10',
        startedAt: inicio,
        label: 'Finca El Mirador · Lote 10',
      );

      final resumen = await AppServices.sync.push();

      expect(resumen.enRevision, 1);
      expect(resumen.confirmadas, 0);
      expect(await AppServices.sync.getPending(), hasLength(1));

      final bandeja = await AppServices.sync.inbox();
      expect(bandeja.single.titulo, 'Visita de campo');
      expect(bandeja.single.enRevision, isTrue);
      expect(bandeja.single.motivo, contains('hora'));
    });
  });
}
