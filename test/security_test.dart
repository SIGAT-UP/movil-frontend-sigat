import 'package:flutter_test/flutter_test.dart';
import 'package:vigilancia_durazno/app/routes.dart';
import 'package:vigilancia_durazno/data/models/user_session.dart';

/// Comprobaciones de las correcciones de seguridad S-01 y S-04.
void main() {
  group('S-01 · Rol desconocido no se trata como Técnico', () {
    test('reconoce los roles válidos', () {
      expect(UserRole.fromString('tecnico'), UserRole.tecnico);
      expect(UserRole.fromString('PRODUCTOR'), UserRole.productor);
      expect(UserRole.fromString(' administrador '), UserRole.administrador);
      expect(UserRole.fromString('agronomo'), UserRole.agronomo);
    });

    test('un rol desconocido NO da acceso de técnico', () {
      expect(UserRole.fromString('agronomo2'), UserRole.desconocido);
      expect(UserRole.fromString('tecnico2'), UserRole.desconocido);
      expect(UserRole.fromString(''), UserRole.desconocido);
      expect(UserRole.fromString(null), UserRole.desconocido);
    });

    test('un rol desconocido no tiene pantalla de inicio', () {
      expect(AppRoutes.homeFor(UserRole.desconocido), isNull);
      expect(AppRoutes.homeFor(UserRole.coordinador), isNull);
      expect(AppRoutes.homeFor(UserRole.tecnico), AppRoutes.home);
      expect(AppRoutes.homeFor(UserRole.productor), AppRoutes.producerHome);
      expect(AppRoutes.homeFor(UserRole.agronomo), AppRoutes.agronomistHome);
    });
  });

  group('Separación de roles en las rutas', () {
    test('el productor no puede abrir rutas del técnico', () {
      expect(AppRoutes.canAccess(AppRoutes.registerReading, UserRole.productor), isFalse);
      expect(AppRoutes.canAccess(AppRoutes.lots, UserRole.productor), isFalse);
    });

    test('el técnico no puede abrir rutas del productor', () {
      expect(AppRoutes.canAccess(AppRoutes.producerHarvest, UserRole.tecnico), isFalse);
    });

    test('sin sesión no se accede a rutas con dueño', () {
      expect(AppRoutes.canAccess(AppRoutes.lots, null), isFalse);
    });

    test('los avisos son accesibles para cualquier rol autenticado', () {
      expect(AppRoutes.canAccess(AppRoutes.notifications, UserRole.tecnico), isTrue);
      expect(AppRoutes.canAccess(AppRoutes.notifications, UserRole.productor), isTrue);
    });

    test('nadie más entra a las rutas del agrónomo', () {
      expect(AppRoutes.canAccess(AppRoutes.agroPlanningHub, UserRole.tecnico), isFalse);
      expect(AppRoutes.canAccess(AppRoutes.agroRecords, UserRole.productor), isFalse);
      expect(AppRoutes.canAccess(AppRoutes.agroLotSummary, null), isFalse);
      expect(AppRoutes.canAccess(AppRoutes.agroLotSummary, UserRole.agronomo), isTrue);
    });

    test('el agrónomo no entra a las rutas de campo', () {
      expect(AppRoutes.canAccess(AppRoutes.registerReading, UserRole.agronomo), isFalse);
      expect(AppRoutes.canAccess(AppRoutes.producerHarvest, UserRole.agronomo), isFalse);
    });

    test('las planificaciones exigen sesión con un rol reconocido', () {
      expect(AppRoutes.canAccess(AppRoutes.planningList, UserRole.tecnico), isTrue);
      expect(AppRoutes.canAccess(AppRoutes.planningList, UserRole.productor), isTrue);
      expect(AppRoutes.canAccess(AppRoutes.planningList, null), isFalse);
      expect(AppRoutes.canAccess(AppRoutes.planningList, UserRole.desconocido), isFalse);
    });
  });

  group('S-04 · El token no se expone', () {
    const sesion = UserSession(
      userId: '1',
      username: 'usuario.demo@example.com',
      displayName: 'Tecnico Demo',
      shortName: 'T. Demo',
      role: UserRole.tecnico,
      scope: 'Lote',
      device: 'Móvil',
      token: 'token-secreto-123',
    );

    test('toJson no incluye el token', () {
      expect(sesion.toJson().containsKey('token'), isFalse);
      expect(sesion.toJson().toString(), isNot(contains('token-secreto-123')));
    });

    test('toString no imprime el token', () {
      expect(sesion.toString(), isNot(contains('token-secreto-123')));
    });

    test('el token sigue disponible para el almacenamiento seguro', () {
      expect(sesion.tokenForSecureStorage, 'token-secreto-123');
    });
  });
}

