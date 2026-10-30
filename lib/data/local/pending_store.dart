import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Qué tipo de registro quedó guardado en el teléfono esperando al servidor.
/// Cada uno corresponde a una entidad de `POST /sincronizacion/lotes` (`EntidadSync`).
enum PendingKind {
  lectura('lectura_trampa', 'Lectura de trampa'),
  justificacion('lectura_trampa', 'Trampa no leída'),
  visita('visita', 'Visita'),
  resultadoLote('planificacion_lote', 'Resultado de actividad'),
  aplicacion('aplicacion_fitosanitaria', 'Aplicación fitosanitaria'),
  cosecha('cosecha', 'Cosecha');

  const PendingKind(this.entity, this.label);

  /// Nombre de la entidad en el contrato de sincronización del backend.
  final String entity;
  final String label;

  static PendingKind fromName(String v) =>
      PendingKind.values.firstWhere((k) => k.name == v, orElse: () => PendingKind.lectura);
}

/// Registro capturado en el teléfono y TODAVÍA NO CONFIRMADO por el servidor.
///
/// Nunca se marca como enviado sin una respuesta del backend: mientras exista aquí,
/// la app lo muestra como «Guardado en este teléfono · pendiente de enviar».
class PendingRecord {
  const PendingRecord({
    required this.id,
    required this.ownerId,
    required this.kind,
    required this.label,
    required this.observedAt,
    required this.payload,
    this.lotId,
    this.lastError,
    this.lastAttemptAt,
  });

  /// Identificador lógico generado en el teléfono (será `*_registro_id` en el servidor).
  final String id;

  /// Usuario que lo capturó: cada usuario solo ve y envía lo suyo.
  final String ownerId;
  final PendingKind kind;
  final String label;
  final DateTime observedAt;

  /// Datos capturados, en el formato del modelo de la app.
  final Map<String, dynamic> payload;
  final String? lotId;

  /// Último motivo por el que no se pudo enviar (sin conexión, servidor no disponible…).
  final String? lastError;
  final DateTime? lastAttemptAt;

  PendingRecord withError(String error) => PendingRecord(
        id: id,
        ownerId: ownerId,
        kind: kind,
        label: label,
        observedAt: observedAt,
        payload: payload,
        lotId: lotId,
        lastError: error,
        lastAttemptAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner_id': ownerId,
        'kind': kind.name,
        'label': label,
        'observed_at': observedAt.toIso8601String(),
        'payload': payload,
        'lot_id': lotId,
        'last_error': lastError,
        'last_attempt_at': lastAttemptAt?.toIso8601String(),
      };

  factory PendingRecord.fromJson(Map<String, dynamic> j) => PendingRecord(
        id: j['id'] as String,
        ownerId: j['owner_id'] as String,
        kind: PendingKind.fromName(j['kind'] as String),
        label: j['label'] as String,
        observedAt: DateTime.parse(j['observed_at'] as String),
        payload: Map<String, dynamic>.from(j['payload'] as Map),
        lotId: j['lot_id'] as String?,
        lastError: j['last_error'] as String?,
        lastAttemptAt: j['last_attempt_at'] == null ? null : DateTime.parse(j['last_attempt_at'] as String),
      );
}

/// Cola de registros pendientes de sincronizar, guardada en el teléfono.
abstract class PendingStore {
  /// Pendientes de [ownerId], del más antiguo al más reciente.
  Future<List<PendingRecord>> forOwner(String ownerId);

  /// Guarda o reemplaza (mismo [PendingRecord.id]). Nunca reemplaza un registro de OTRO dueño:
  /// en ese caso lanza [StateError] y la cola queda igual.
  Future<void> put(PendingRecord record);

  /// Lo quita SOLO cuando el servidor confirmó que lo recibió.
  Future<void> remove(String id);
}

/// Implementación persistente: sobrevive a cerrar la app y a reiniciar el teléfono.
///
/// Guarda JSON en `shared_preferences` (SharedPreferences en Android, NSUserDefaults en
/// iOS, localStorage en web). Son registros pequeños (lecturas, autorreportes); las FOTOS
/// no se guardan aquí: solo su ruta y metadatos.
class SharedPrefsPendingStore implements PendingStore {
  static const _clave = 'sigat.pendientes.v1';

  Future<List<PendingRecord>> _todos() async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(_clave);
    if (texto == null || texto.isEmpty) return [];
    try {
      final lista = jsonDecode(texto) as List;
      return [for (final x in lista) PendingRecord.fromJson(Map<String, dynamic>.from(x as Map))];
    } catch (_) {
      // Un valor dañado no debe bloquear la app; se conserva tal cual para revisarlo.
      await prefs.setString('$_clave.danado.${DateTime.now().millisecondsSinceEpoch}', texto);
      await prefs.remove(_clave);
      return [];
    }
  }

  Future<void> _guardar(List<PendingRecord> lista) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clave, jsonEncode([for (final r in lista) r.toJson()]));
  }

  @override
  Future<List<PendingRecord>> forOwner(String ownerId) async =>
      (await _todos()).where((r) => r.ownerId == ownerId).toList()
        ..sort((a, b) => a.observedAt.compareTo(b.observedAt));

  @override
  Future<void> put(PendingRecord record) async {
    final lista = await _todos();
    _noDeOtroDueno(lista.where((r) => r.id == record.id), record);
    lista.removeWhere((r) => r.id == record.id);
    lista.add(record);
    await _guardar(lista);
  }

  @override
  Future<void> remove(String id) async {
    final lista = await _todos();
    lista.removeWhere((r) => r.id == id);
    await _guardar(lista);
  }
}

/// Para pruebas: misma semántica, en memoria.
class InMemoryPendingStore implements PendingStore {
  final _items = <String, PendingRecord>{};

  @override
  Future<List<PendingRecord>> forOwner(String ownerId) async =>
      _items.values.where((r) => r.ownerId == ownerId).toList()
        ..sort((a, b) => a.observedAt.compareTo(b.observedAt));

  @override
  Future<void> put(PendingRecord record) async {
    final existente = _items[record.id];
    _noDeOtroDueno([if (existente != null) existente], record);
    _items[record.id] = record;
  }

  @override
  Future<void> remove(String id) async => _items.remove(id);
}

/// Un registro con el mismo id pero de otro dueño no se reemplaza (se perdería un dato de campo).
void _noDeOtroDueno(Iterable<PendingRecord> existentes, PendingRecord nuevo) {
  for (final e in existentes) {
    if (e.ownerId != nuevo.ownerId) {
      throw StateError('El registro ${nuevo.id} pertenece a otra cuenta y no se reemplaza.');
    }
  }
}
