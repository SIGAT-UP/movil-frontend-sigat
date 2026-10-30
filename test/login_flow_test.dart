import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigilancia_durazno/app/app.dart';
import 'package:vigilancia_durazno/features/auth/logout.dart';

import 'support/backend_de_prueba.dart';

/// Inicio de sesión con el repositorio REAL (`ApiAuthRepository` + `ApiClient`) contra un
/// doble del backend que habla el mismo contrato. No hay usuarios ni contraseñas fijas:
/// cada prueba crea sus cuentas con una contraseña aleatoria.
void main() {
  late BackendDePrueba backend;
  late String claveTecnico;
  late String claveProductor;
  late String claveAgronomo;

  setUp(() {
    clearSessionState();
    backend = BackendDePrueba();
    claveTecnico = backend.crearCuenta(
      usuario: 'tecnico.demo',
      nombre: 'Tecnico Demo',
      rol: 'TECNICO',
    );
    claveProductor = backend.crearCuenta(
      usuario: 'carlos.prod',
      nombre: 'Carlos Rondón',
      rol: 'PRODUCTOR',
    );
    claveAgronomo = backend.crearCuenta(
      usuario: 'sara.agro',
      nombre: 'Sara Supervisora',
      rol: 'AGRONOMO_SUPERVISOR',
    );
    backend.conectarApp();
  });

  /// Lleva el elemento a la vista y lo toca, como haría una persona.
  Future<void> tocar(WidgetTester tester, Finder objetivo) async {
    await tester.ensureVisible(objetivo);
    await tester.pumpAndSettle();
    await tester.tap(objetivo);
  }

  Future<void> entrar(WidgetTester tester, String usuario, String clave) async {
    await tester.pumpWidget(const VigilanciaDuraznoApp());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), usuario);
    await tester.enterText(find.byType(TextFormField).at(1), clave);
    await tocar(tester, find.text('Iniciar sesión'));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  testWidgets('Login con credenciales incorrectas muestra el mensaje del servidor', (tester) async {
    await entrar(tester, 'tecnico.demo', 'no-es-la-clave');
    expect(find.text('No pudimos iniciar sesión'), findsOneWidget);
    expect(find.text('Usuario o contraseña incorrectos.'), findsOneWidget);
    expect(backend.peticiones, contains('POST /auth/login'));
  });

  testWidgets('Login correcto (usuario creado en la BD) lleva a Contexto de acceso e Inicio', (tester) async {
    await entrar(tester, 'tecnico.demo', claveTecnico);
    expect(find.text('Hola, Tecnico'), findsOneWidget);

    await tester.tap(find.text('Continuar'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Mis Lotes Asignados'), findsOneWidget);
    // El inicio pidió su resumen al servidor; los conteos que el servidor aún no envía se ven como «—».
    expect(backend.peticiones, contains('GET /yo/inicio'));
    expect(find.text('—'), findsWidgets);
  });

  testWidgets('El productor entra a SU inicio y no ve las pestañas del técnico', (tester) async {
    await entrar(tester, 'carlos.prod', claveProductor);
    expect(find.text('Productor'), findsOneWidget);

    await tester.tap(find.text('Continuar'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Registrar aplicación'), findsOneWidget);
    expect(find.text('Registrar cosecha'), findsOneWidget);
    expect(find.text('Trampas'), findsNothing);
    // /productor/cultivo aún no existe en el servidor (501): se dice, no se inventa el cultivo.
    expect(find.text('No se pudo cargar tu cultivo'), findsOneWidget);
    expect(find.textContaining('todavía no está disponible en el servidor'), findsWidgets);
  });

  testWidgets('Sin conexión el login lo dice (no da por buena la sesión)', (tester) async {
    backend.sinRed = true;
    await entrar(tester, 'tecnico.demo', claveTecnico);
    expect(find.text('Sin conexión'), findsOneWidget);
    expect(find.text('Mis Lotes Asignados'), findsNothing);
  });

  Future<void> continuar(WidgetTester tester) async {
    await tester.tap(find.text('Continuar'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }

  testWidgets('Técnico: cerrar sesión arriba y «Pendiente de visita» abre los lotes pendientes', (tester) async {
    await entrar(tester, 'tecnico.demo', claveTecnico);
    await continuar(tester);

    // Entrar a lotes pendientes
    await tocar(tester, find.text('Pendiente de visita'));
    await tester.pumpAndSettle();
    expect(find.text('Lotes asignados'), findsOneWidget);
    expect(backend.peticiones, contains('GET /lotes'));

    // Regresar al Inicio
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    // Navegar a la pestaña Perfil/Más del técnico en la barra inferior/lateral
    final pestanaPerfil = find.byIcon(Icons.more_horiz);
    if (pestanaPerfil.evaluate().isNotEmpty) {
      await tester.tap(pestanaPerfil);
    } else {
      await tester.tap(find.byIcon(Icons.person));
    }
    await tester.pumpAndSettle();

    // Buscar y presionar 'Cerrar sesión' asegurando que se haga scroll si está fuera de pantalla
    final botonCerrarSesion = find.text('Cerrar sesión');
    await tester.scrollUntilVisible(
      botonCerrarSesion,
      50.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(botonCerrarSesion);
    await tester.pumpAndSettle();

    expect(
      find.text('Los datos sin sincronizar permanecen guardados en el dispositivo.'),
      findsOneWidget,
    );
  });

  testWidgets('Productor: pestaña Perfil con sus propias opciones', (tester) async {
    await entrar(tester, 'carlos.prod', claveProductor);
    await continuar(tester);

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Mi perfil'), findsOneWidget);
    expect(find.text('Productor · Vigilancia Fitosanitaria'), findsOneWidget);
    expect(find.text('Agregar foto'), findsOneWidget);
    expect(find.text('Lotes asignados'), findsNothing); // eso es del técnico
    expect(backend.peticiones, contains('GET /yo/perfil'));
  });

  testWidgets('Agrónomo: pestaña Perfil con sus propias opciones', (tester) async {
    await entrar(tester, 'sara.agro', claveAgronomo);
    await continuar(tester);

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Mi perfil'), findsOneWidget);
    expect(find.text('Agrónomo / Supervisor · Vigilancia Fitosanitaria'), findsOneWidget);
    expect(find.text('Resumen del lote'), findsOneWidget);
    expect(find.text('Historial de visitas'), findsNothing); // eso es del técnico
  });
}
