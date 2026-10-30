import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vigilancia_durazno/data/app_services.dart';
import 'package:vigilancia_durazno/data/local/pending_store.dart';
import 'package:vigilancia_durazno/data/local/record_owner.dart';
import 'package:vigilancia_durazno/data/models/photo_file.dart';
import 'package:vigilancia_durazno/data/models/producer.dart';
import 'package:vigilancia_durazno/data/models/reading.dart';
import 'package:vigilancia_durazno/data/repositories/field_repositories.dart';
import 'package:vigilancia_durazno/features/auth/logout.dart';

import 'support/backend_de_prueba.dart';

/// Dueño de los registros de la cola local: sin sesión válida no se guarda, no se borra ni se
/// lee nada, y dos cuentas en el mismo teléfono nunca ven lo del otro.
void main() {
  late BackendDePrueba backend;
  late PendingStore cola;
  late String claveA;
  late String claveB;

  Reading lectura(String id) => Reading(
        id: id,
        trapId: '3',
        trapLabel: 'T-003',
        lotId: '10',
        observedAt: DateTime(2026, 10, 29, 9),
        specimens: 2,
        condition: TrapCondition.buenEstado,
      );

  PhytoApplication aplicacion(String id) => PhytoApplication(
        id: id,
        date: DateTime(2026, 10, 28),
        product: 'Producto X',
        doseMlPerLiter: 2,
        areaHa: 1,
        responsible: 'Responsable',
      );

  Future<void> entrar(String usuario, String clave) async {
    AppServices.session.value = await AppServices.auth.login(username: usuario, password: clave, remember: false);
  }

  setUp(() {
    backend = BackendDePrueba();
    claveA = backend.crearCuenta(usuario: 'tec.a', nombre: 'Técnico A', rol: 'TECNICO', id: 11);
    claveB = backend.crearCuenta(usuario: 'tec.b', nombre: 'Técnico B', rol: 'TECNICO', id: 12);
    cola = backend.conectarApp();
    AppServices.session.value = null;
  });
  tearDown(clearSessionState);

  group('RecordOwner', () {
    test('solo acepta identificadores numéricos no vacíos', () {
      expect(RecordOwner.esValido('11'), isTrue);
      for (final malo in [null, '', ' ', 'null', 'abc', '1 2', '-1']) {
        expect(RecordOwner.esValido(malo), isFalse, reason: '«$malo»');
      }
    });

    test('sin sesión: requerido() lanza y paraLectura() no coincide con ningún dueño', () {
      expect(RecordOwner.requerido, throwsA(isA<SinSesionException>()));
      expect(RecordOwner.paraLectura(), RecordOwner.ninguno);
      expect(RecordOwner.paraLectura(''), RecordOwner.ninguno);
      expect(RecordOwner.paraLectura('11'), RecordOwner.ninguno); // un id válido sin sesión tampoco
    });

    test('con sesión: paraLectura() solo devuelve el usuario de la sesión', () async {
      await entrar('tec.a', claveA);
      expect(RecordOwner.paraLectura(), '11');
      expect(RecordOwner.paraLectura('11'), '11');
      for (final ajeno in ['12', '', ' 11', '11 ', 'abc', '-', '011']) {
        expect(RecordOwner.paraLectura(ajeno), RecordOwner.ninguno, reason: '«$ajeno»');
      }
    });
  });

  group('Guardar sin sesión', () {
    test('lectura, justificación, aplicación y cosecha se rechazan y la cola queda igual', () async {
      await expectLater(() => AppServices.readings.saveReading(lectura('l-1')), throwsA(isA<SinSesionException>()));
      await expectLater(
        () => AppServices.readings.justifyTrap(trapId: '3', lotId: '10', reason: 'No encontrada'),
        throwsA(isA<SinSesionException>()),
      );
      await expectLater(() => AppServices.producer.saveApplication(aplicacion('a-1')), throwsA(isA<SinSesionException>()));
      expect(await cola.forOwner(''), isEmpty);
      expect(await cola.forOwner(RecordOwner.ninguno), isEmpty);
    });

    test('sin sesión no se borra la lectura anterior de nadie', () async {
      await entrar('tec.a', claveA);
      await AppServices.readings.saveReading(lectura('l-1'));
      AppServices.session.value = null;
      await expectLater(() => AppServices.readings.saveReading(lectura('l-2')), throwsA(isA<SinSesionException>()));
      expect((await cola.forOwner('11')).map((r) => r.id), ['l-1']);
    });
  });

  group('Aislamiento entre cuentas', () {
    test('lo que guarda A no lo ve B, y vuelve a estar cuando A entra de nuevo', () async {
      await entrar('tec.a', claveA);
      await AppServices.readings.saveReading(lectura('l-a'));
      expect((await AppServices.sync.getPending()).single.ownerId, '11');

      clearSessionState();
      await entrar('tec.b', claveB);
      expect(await AppServices.sync.getPending(), isEmpty);
      expect(await AppServices.readings.readingsForLot('10'), isEmpty);

      clearSessionState();
      await entrar('tec.a', claveA);
      expect((await AppServices.sync.getPending()).single.id, 'l-a');
    });

    test('markLotExecutedForUser solo acepta al usuario de la sesión', () async {
      await entrar('tec.a', claveA);
      await expectLater(
        () => AppServices.plannings.markLotExecutedForUser('12', 'Lote A'),
        throwsA(isA<SinSesionException>()),
      );
      await expectLater(
        () => AppServices.plannings.markLotExecutedForUser('', 'Lote A'),
        throwsA(isA<SinSesionException>()),
      );
      expect(await cola.forOwner('12'), isEmpty);
      await AppServices.plannings.markLotExecutedForUser('11', 'Lote A');
      expect((await cola.forOwner('11')).single.kind, PendingKind.resultadoLote);
    });

    test('un registro de otra cuenta con el mismo id no se reemplaza', () async {
      await entrar('tec.a', claveA);
      await AppServices.readings.saveReading(lectura('mismo-id'));
      clearSessionState();
      await entrar('tec.b', claveB);
      await expectLater(() => AppServices.readings.saveReading(lectura('mismo-id')), throwsA(isA<StateError>()));
      expect((await cola.forOwner('11')).single.id, 'mismo-id'); // el de A sigue intacto
      expect(await cola.forOwner('12'), isEmpty);
    });

    test('registros antiguos sin dueño se conservan pero nadie los ve', () async {
      await cola.put(PendingRecord(
        id: 'huerfano',
        ownerId: '',
        kind: PendingKind.lectura,
        label: 'Registro antiguo',
        observedAt: DateTime(2026, 1, 1),
        payload: const {},
      ));
      expect(await AppServices.sync.getPending(), isEmpty); // sin sesión
      await entrar('tec.a', claveA);
      expect(await AppServices.sync.getPending(), isEmpty);
      expect((await cola.forOwner('')).single.id, 'huerfano'); // sigue guardado
    });
  });

  group('Lecturas con un usuario distinto al de la sesión', () {
    late String claveProdA;
    late String claveProdB;
    setUp(() {
      claveProdA = backend.crearCuenta(usuario: 'prod.a', nombre: 'Productor A', rol: 'PRODUCTOR', id: 21);
      claveProdB = backend.crearCuenta(usuario: 'prod.b', nombre: 'Productor B', rol: 'PRODUCTOR', id: 22);
    });

    Future<List<String>> idsActividad(String userId) async {
      try {
        return [for (final a in await AppServices.producer.getActivity(userId)) a.id];
      } on DataException {
        return const []; // sin registros propios y el servidor responde 501: no hay nada que mostrar
      }
    }

    test('getActivity con el id de otra cuenta no devuelve sus registros locales', () async {
      await entrar('prod.b', claveProdB);
      await AppServices.producer.saveApplication(aplicacion('app-b'));
      clearSessionState();

      await entrar('prod.a', claveProdA);
      await AppServices.producer.saveApplication(aplicacion('app-a'));
      expect(await idsActividad('22'), isNot(contains('app-b')));
      expect(await idsActividad('22'), isNot(contains('app-a')));
      expect(await idsActividad(''), isEmpty);
      expect(await idsActividad('21'), ['app-a']);
      // Los registros de B siguen guardados.
      expect((await cola.forOwner('22')).single.id, 'app-b');
    });

    test('getSummary con el id de otra cuenta no cuenta sus pendientes', () async {
      await entrar('tec.b', claveB);
      await AppServices.readings.saveReading(lectura('l-b1'));
      await AppServices.readings.saveReading(Reading(
        id: 'l-b2',
        trapId: '4',
        trapLabel: 'T-004',
        lotId: '10',
        observedAt: DateTime(2026, 10, 29, 10),
        specimens: 0,
        condition: TrapCondition.buenEstado,
      ));
      clearSessionState();

      await entrar('tec.a', claveA);
      expect((await AppServices.home.getSummary('12')).pendingLocal, 0);
      expect((await AppServices.home.getSummary('')).pendingLocal, 0);
      expect((await AppServices.home.getSummary('11')).pendingLocal, 0);
      await AppServices.readings.saveReading(lectura('l-a'));
      expect((await AppServices.home.getSummary('11')).pendingLocal, 1);
      expect((await AppServices.home.getSummary('12')).pendingLocal, 0);
      expect((await cola.forOwner('12')).length, 2); // nada se borró
    });

    test('la foto de perfil local solo se guarda y se lee para el usuario de la sesión', () async {
      await entrar('tec.a', claveA);
      final foto = PhotoFile(
        path: 'a.jpg',
        bytes: Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xD9]),
        mimeType: 'image/jpeg',
        sizeBytes: 4,
        pickedAt: DateTime(2026, 10, 30),
      );
      await expectLater(
        () => AppServices.profile.saveProfilePhotoLocally('12', foto),
        throwsA(isA<SinSesionException>()),
      );
      await AppServices.profile.saveProfilePhotoLocally('11', foto);
      expect((await AppServices.profile.getProfile('12')).photoBytes, isNull);
      expect((await AppServices.profile.getProfile('11')).photoBytes, isNotNull);
      await expectLater(() => AppServices.profile.removeProfilePhoto('12'), throwsA(isA<SinSesionException>()));
    });
  });
}
