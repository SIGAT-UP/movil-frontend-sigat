import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigilancia_durazno/app/routes.dart';
import 'package:vigilancia_durazno/data/app_services.dart';
import 'package:vigilancia_durazno/data/local/pending_store.dart';
import 'package:vigilancia_durazno/data/models/user_session.dart';
import 'package:vigilancia_durazno/data/repositories/auth_repository.dart';
import 'package:vigilancia_durazno/features/auth/logout.dart';

import 'support/backend_de_prueba.dart';

/// El cierre de sesión limpia la sesión aunque falle la red o el repositorio, y conserva los
/// registros pendientes del teléfono.
class _AuthQueFalla implements AuthRepository {
  @override
  Future<void> logout() async => throw StateError('almacenamiento no disponible');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  tearDown(clearSessionState);

  test('sin red: logout borra los tokens del dispositivo y conserva los pendientes', () async {
    final backend = BackendDePrueba();
    final clave = backend.crearCuenta(usuario: 'tec.prueba', nombre: 'Técnico Prueba', rol: 'TECNICO', id: 5);
    final cola = backend.conectarApp();
    AppServices.session.value = await AppServices.auth.login(username: 'tec.prueba', password: clave, remember: false);
    await cola.put(PendingRecord(
      id: 'p-1',
      ownerId: '5',
      kind: PendingKind.lectura,
      label: 'Pendiente',
      observedAt: DateTime(2026, 10, 29),
      payload: const {},
    ));
    expect(await AppServices.api.store.accessToken, isNotNull);

    backend.sinRed = true;
    await AppServices.auth.logout();

    expect(await AppServices.api.store.accessToken, isNull);
    expect(await AppServices.api.store.refreshToken, isNull);
    expect(await AppServices.api.store.sessionUser, isNull);
    expect((await cola.forOwner('5')).single.id, 'p-1');
  });

  testWidgets('si el repositorio falla, la sesión en memoria se cierra igual', (tester) async {
    final real = AppServices.auth;
    AppServices.auth = _AuthQueFalla();
    addTearDown(() => AppServices.auth = real);
    AppServices.session.value = const UserSession(
      userId: '5',
      username: 'tec.prueba',
      displayName: 'Técnico Prueba',
      shortName: 'T. Prueba',
      role: UserRole.tecnico,
      scope: 'Lote',
      device: 'Móvil',
      token: 't',
    );

    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      }),
      routes: {AppRoutes.login: (_) => const Text('pantalla de login')},
    ));

    await logoutNow(ctx);
    await tester.pumpAndSettle();

    expect(AppServices.session.value, isNull);
    expect(find.text('pantalla de login'), findsOneWidget);
  });
}
