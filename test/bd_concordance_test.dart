
import 'package:flutter_test/flutter_test.dart';
import 'package:vigilancia_durazno/data/models/lot.dart';
import 'package:vigilancia_durazno/data/models/planning.dart';
import 'package:vigilancia_durazno/data/models/reading.dart';
import 'package:vigilancia_durazno/data/models/trap.dart';
import 'package:vigilancia_durazno/data/models/user_session.dart';

/// La app debe hablar el mismo idioma que la BD SIGAT v9 y que el contrato del backend.
void main() {
  group('Roles (rol.rol_codigo)', () {
    test('reconoce los 4 códigos de la BD', () {
      expect(UserRole.fromString('ADMINISTRADOR'), UserRole.administrador);
      expect(UserRole.fromString('AGRONOMO_SUPERVISOR'), UserRole.agronomo);
      expect(UserRole.fromString('TECNICO'), UserRole.tecnico);
      expect(UserRole.fromString('PRODUCTOR'), UserRole.productor);
    });

    test('un rol desconocido no abre ninguna pantalla', () {
      expect(UserRole.fromString('INVENTADO'), UserRole.desconocido);
      expect(UserRole.fromString(null), UserRole.desconocido);
    });

    test('la sesión se arma con la respuesta de POST /auth/login', () {
      final s = UserSession.fromApi({
        'token': 'abc',
        'user': {
          'id': 3,
          'rol': 'TECNICO',
          'nombre': 'Técnico Demo',
          'usuario': 'tecnico.demo',
        },
      });
      expect(s.role, UserRole.tecnico);
      expect(s.shortName, 'T. Demo');
      expect(s.userId, '3');
    });
  });

  group('Trampas (RN-005 y código oficial)', () {
    test('trapFromApi lee una fila de Trampa (GET /trampas)', () {
      final t = trapFromApi({
        'tram_id': 2,
        'tram_codigo': '54518-602-2',
        'tipo': 'McPhail',
        'lote_id': 1,
        'longitud': -72.6485,
        'latitud': 7.3705,
        'celda': 'A2',
        'estado': 'activo',
      });
      expect(t.label, 'ICA-002');
      expect(t.icaCode, matches(RegExp(r'^54518-602-\d+$')));
      expect(t.type, 'McPhail');
      expect(t.active, isTrue);
    });
  });

  group('Lotes', () {
    test('lotFromApi lee una fila de v_lote_app', () {
      final l = lotFromApi({
        'lote_id': 1,
        'lote_codigo': 'A',
        'lote_descripcion': 'Lote A',
        'lote_area': 2.5,
        'pred_id': 1,
        'pred_nombre': 'Finca El Mirador',
        'productor': 'Pedro Productor',
        'municipio': 'Pamplona',
        'cultivo': 'Durazno',
        'vigilancia_activa': true,
        'trampas_vigentes': 3,
      });
      expect(l.code, 'LOTE-A');
      expect(l.trapCount, 3);
      expect(l.status, LotStatus.pendiente);
      // El dueño y el productor son la misma persona: salen del predio.
      expect(l.owner, l.producer);
    });
  });

  group('Lecturas (lectura_trampa)', () {
    Reading lectura(TrapCondition c) => Reading(
          id: 'r1',
          trapId: '1',
          trapLabel: 'ICA-001',
          lotId: '1',
          observedAt: DateTime(2026, 10, 8, 10),
          specimens: 2,
          condition: c,
          observations: 'nota',
        );

    test('en buen estado = condición 1 (Normal) y leída', () {
      final p = lectura(TrapCondition.buenEstado).toSyncPayload(visitId: 'v');
      expect(p['cond_id'], 1);
      expect(p['lect_leida'], isTrue);
      expect(p['lect_especimenes'], 2);
    });

    test('dañada, caída y sin atrayente = condición 2 (Dañada)', () {
      for (final c in [
        TrapCondition.danada,
        TrapCondition.caida,
        TrapCondition.sinAtrayente,
      ]) {
        expect(lectura(c).toSyncPayload(visitId: 'v')['cond_id'], 2);
      }
    });

    test('no encontrada = no leída, sin conteo y con justificación', () {
      final p = lectura(TrapCondition.noEncontrada).toSyncPayload(visitId: 'v');
      expect(p['lect_leida'], isFalse);
      expect(p['lect_especimenes'], isNull);
      expect(p['lect_justificacion'], 'nota');
    });
  });

  group('Planificación desde la API', () {
    test('planFromApi: el destino se deduce del rol del destinatario', () {
      final p = Planning.fromApi({
        'plan_id': 7,
        'plan_actividad': 'Muestreo',
        'plan_fecha_inicio': '2026-11-22',
        'plan_estado': 'pendiente',
        'plan_creada_en': '2026-11-15T10:00:00Z',
        'usua_id_destinatario': 3,
        'destinatario': 'Técnico Demo',
        'rol_destinatario': 'Técnico',
        'creador': 'Sara Supervisora',
        'lotes': ['A', 'C'],
        'plan_id_origen': 4,
      });
      expect(p.target, PlanningTarget.tecnico);
      expect(p.lotNames, ['Lote A', 'Lote C']);
      expect(p.originId, '4');
      expect(p.recipientCanRespond, isFalse);
    });
  });
}
