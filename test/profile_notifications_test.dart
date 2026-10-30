
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigilancia_durazno/app/app.dart';
import 'package:vigilancia_durazno/features/auth/logout.dart';
import 'package:vigilancia_durazno/features/profile/profile_screen.dart';

import 'support/backend_de_prueba.dart';

/// Avisos y perfil contra el contrato del backend: la bandeja muestra lo que entrega el
/// servidor y las preferencias no se dan por guardadas mientras el servidor no las reciba.
void main() {
  late BackendDePrueba backend;
  late String clave;

  setUp(() {
    clearSessionState();
    backend = BackendDePrueba();
    clave = backend.crearCuenta(
      usuario: 'tecnico.demo',
      nombre: 'Tecnico Demo',
      rol: 'TECNICO',
      id: 7,
    );
    backend.conectarApp();
  });

  /// Lleva el elemento a la vista y lo toca, como haría una persona.
  Future<void> tocar(WidgetTester tester, Finder objetivo) async {
    await tester.ensureVisible(objetivo);
    await tester.pumpAndSettle();
    await tester.tap(objetivo);
  }

  /// La lista de "Más" se construye a medida que se desplaza: lo que está
  /// debajo del borde visible no existe para el buscador hasta llegar a él.
  Future<void> bajarHasta(WidgetTester tester, Finder objetivo) async {
    await tester.scrollUntilVisible(
      objetivo,
      200,
      scrollable: find.descendant(
        of: find.byType(ProfileScreen),
        matching: find.byType(Scrollable),
      ).first,
    );
    // Que quede completo en pantalla, no solo asomado, para poder tocarlo.
    await tester.ensureVisible(objetivo);
    await tester.pumpAndSettle();
  }

  Future<void> entrarComoTecnico(WidgetTester tester) async {
    await tester.pumpWidget(const VigilanciaDuraznoApp());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'tecnico.demo');
    await tester.enterText(find.byType(TextFormField).at(1), clave);
    await tocar(tester, find.text('Iniciar sesión'));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }

  // Más › Notificaciones abre la BANDEJA (la misma de la campana), con los avisos que
  // entrega el servidor; las preferencias están dentro, en el botón de ajustes.
  testWidgets('La bandeja muestra los avisos del servidor y los marca como leídos', (tester) async {
    backend.agregarAviso(
      usuaId: 7,
      titulo: 'Nueva asignación',
      cuerpo: 'Te asignaron el lote A.',
    );
    await entrarComoTecnico(tester);

    await tester.tap(find.text('Más'));
    await tester.pumpAndSettle();
    await bajarHasta(tester, find.text('Notificaciones'));
    await tester.tap(find.text('Notificaciones'));
    await tester.pumpAndSettle();

    expect(backend.peticiones, contains('GET /yo/notificaciones'));
    expect(find.text('Nueva asignación'), findsOneWidget);
    expect(find.text('Te asignaron el lote A.'), findsOneWidget);
    expect(find.textContaining('DEMOSTRACIÓN'), findsNothing);

    await tester.tap(find.text('Nueva asignación'));
    await tester.pumpAndSettle();
    expect(backend.peticiones, contains('POST /yo/notificaciones/1/leida'));
  });

  testWidgets('Si el servidor aún no guarda preferencias, el interruptor vuelve atrás y lo dice', (tester) async {
    await entrarComoTecnico(tester);
    await tester.tap(find.text('Más'));
    await tester.pumpAndSettle();
    await bajarHasta(tester, find.text('Notificaciones'));
    await tester.tap(find.text('Notificaciones'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Preferencias de notificaciones'));
    await tester.pumpAndSettle();
    expect(find.text('Recibir notificaciones'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // PUT /yo/preferencias-notificacion responde 501: no se finge que se guardó.
    expect(backend.peticiones, contains('PUT /yo/preferencias-notificacion'));
    expect(find.text('El servidor todavía no guarda tus preferencias de avisos.'), findsWidgets);
    expect(find.text('Desactivadas'), findsNothing);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
  });

  testWidgets('El perfil ofrece agregar fotografía', (tester) async {
    await entrarComoTecnico(tester);
    await tester.tap(find.text('Más'));
    await tester.pumpAndSettle();
    expect(find.text('Agregar foto'), findsOneWidget);
  });
}
