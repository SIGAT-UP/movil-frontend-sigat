import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigilancia_durazno/app/app.dart';
import 'package:vigilancia_durazno/data/app_services.dart';
import 'package:vigilancia_durazno/data/models/user_session.dart';
import 'package:vigilancia_durazno/features/auth/logout.dart';
import 'package:vigilancia_durazno/features/splash/splash_screen.dart';

import 'support/backend_de_prueba.dart';

/// Bienvenida animada: se ve al abrir la app y termina en el login, o en el
/// inicio del rol si ya hay una sesión abierta.
void main() {
  late BackendDePrueba backend;

  setUp(() {
    clearSessionState();
    // Repositorios reales contra un doble del backend (sin red).
    backend = BackendDePrueba();
    backend.conectarApp();
  });

  testWidgets('Muestra logo y frase, y termina en el login', (tester) async {
    await tester.pumpWidget(const VigilanciaDuraznoApp());

    // Cuando el logo acaba de llegar, la frase todavía no se ve: va DESPUÉS.
    await tester.pump(const Duration(milliseconds: 1300));
    final frase = tester.widget<FadeTransition>(
      find.ancestor(of: find.text(SplashScreen.tagline), matching: find.byType(FadeTransition)).first,
    );
    expect(frase.opacity.value, 0);

    // En la pausa (2,2 s a 3,4 s): la frase ya se lee y el login no está.
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text(SplashScreen.tagline), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsNothing);

    // Al terminar: login con su tarjeta de bienvenida; la splash ya no existe.
    await tester.pumpAndSettle();
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.text('Te damos la bienvenida'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });

  testWidgets('Con "reducir movimiento" arranca quieta y también llega al login', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await tester.pumpWidget(const VigilanciaDuraznoApp());
    await tester.pump();
    // Sin desplazamientos: la frase está visible desde el primer momento.
    expect(find.text(SplashScreen.tagline), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });

  testWidgets('Con una sesión abierta salta directo al inicio del rol', (tester) async {
    AppServices.session.value = const UserSession(
      userId: '1',
      username: 'tecnico.demo@example.com',
      displayName: 'Tecnico Demo',
      shortName: 'T. Demo',
      role: UserRole.tecnico,
      scope: 'Lote de durazno',
      device: 'Móvil',
      token: 'token-de-prueba',
    );
    addTearDown(() => AppServices.session.value = null);

    await tester.pumpWidget(const VigilanciaDuraznoApp());
    await tester.pumpAndSettle();

    expect(find.text('Iniciar sesión'), findsNothing);
    expect(find.text('Mis Lotes Asignados'), findsOneWidget);
  });

  testWidgets('Al reabrir la app restaura la sesión guardada con GET /auth/sesion', (tester) async {
    final clave = backend.crearCuenta(usuario: 'tecnico.demo', nombre: 'Tecnico Demo', rol: 'TECNICO');
    // Un inicio de sesión anterior dejó los tokens en el almacenamiento seguro.
    await AppServices.auth.login(username: 'tecnico.demo', password: clave, remember: false);
    expect(AppServices.session.value, isNull); // la app recién abierta no tiene sesión en memoria

    await tester.pumpWidget(const VigilanciaDuraznoApp());
    await tester.pumpAndSettle();

    expect(backend.peticiones, contains('GET /auth/sesion'));
    expect(AppServices.session.value?.username, 'tecnico.demo');
    expect(find.text('Iniciar sesión'), findsNothing);
    expect(find.text('Mis Lotes Asignados'), findsOneWidget);
  });

  testWidgets('Sin tokens guardados la bienvenida termina en el login', (tester) async {
    await tester.pumpWidget(const VigilanciaDuraznoApp());
    await tester.pumpAndSettle();
    expect(backend.peticiones, isNot(contains('GET /auth/sesion')));
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}
