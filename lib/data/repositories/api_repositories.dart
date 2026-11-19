import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/canonical_json.dart';
import '../api/api_client.dart';
import '../api/secure_store.dart';
import '../app_services.dart';
import '../local/pending_store.dart';
import '../local/record_owner.dart';
import '../models/app_notification.dart';
import '../models/field_record.dart';
import '../models/home_summary.dart';
import '../models/lot.dart';
import '../models/lot_summary.dart';
import '../models/photo_file.dart';
import '../models/planning.dart';
import '../models/producer.dart';
import '../models/reading.dart';
import '../models/sync_models.dart';
import '../models/trap.dart';
import '../models/user_profile.dart';
import '../models/user_session.dart';
import '../models/visit.dart';
import 'agronomist_repository.dart';
import 'field_repositories.dart';
import 'home_repository.dart';
import 'notifications_repository.dart';
import 'planning_repository.dart';
import 'producer_repository.dart';
import 'profile_repository.dart';

/// Implementaciones REALES de los contratos de la app contra `sigat-durazno-api`.
///
/// Estado del backend (29-oct-2026):
///
/// | Módulo | Rutas | Estado |
/// |---|---|---|
/// | Avisos | `GET /yo/notificaciones`, `/conteo`, `POST …/leida(s)` | FUNCIONA |
/// | Perfil | `GET /yo/perfil` | FUNCIONA (foto: pendiente `/archivos`) |
/// | Inicio | `GET /yo/inicio` | FUNCIONA (conteos del técnico: pendiente) |
/// | Lotes y trampas (consulta) | `GET /lotes…`, `GET /trampas…` | FUNCIONA |
/// | Visitas, revisión, resumen, programa | `/visitas`, `/revisiones…`, `/lotes/{id}/resumen` | 501 |
/// | Productor | `/productor/cultivo`, `/actividad` | 501 |
/// | Planificación | `/planificaciones…` | 501 |
/// | Sincronización | `POST /sincronizacion/lotes` | 501 |
///
/// Cuando una ruta responde 501, la pantalla muestra «…todavía no está disponible en el
/// servidor» ([NotAvailableYet]); nunca datos inventados. Lo que el técnico o el productor
/// capturan en campo se guarda en el TELÉFONO ([PendingStore]) y queda «pendiente de
/// enviar» hasta que el servidor confirme que lo recibió.

/// Dueño para CONSULTAR la cola local. Para guardar se usa [RecordOwner.requerido].
String get _yo => RecordOwner.paraLectura();

/// Traduce los errores del cliente HTTP a mensajes para la pantalla.
Future<T> _llamar<T>(String que, Future<T> Function() llamada) async {
  try {
    return await llamada();
  } on ApiException catch (e) {
    if (e.isNotImplemented) {
      throw NotAvailableYet('$que: todavía no está disponible en el servidor.');
    }
    if (e.isNetwork) throw OfflineException('$que: ${e.detail}');
    throw DataException(e.detail);
  }
}

DateTime? _fecha(dynamic v) =>
    v == null ? null : DateTime.tryParse(v as String)?.toLocal();
double? _num(dynamic v) => v == null
    ? null
    : (v is num ? v.toDouble() : double.tryParse(v.toString()));
int _int(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
String? _hora(DateTime? d) =>
    d == null ? null : '${d.hour}:${d.minute.toString().padLeft(2, '0')}';

const _pendienteDeEnviar = 'Guardado en este teléfono · pendiente de enviar';

/* ============================================================== inicio */

class ApiHomeRepository implements HomeRepository {
  ApiHomeRepository(this._api, this._pendientes);
  final ApiClient _api;
  final PendingStore _pendientes;

  @override
  Future<HomeSummary> getSummary(String userId) async {
    final locales =
        (await _pendientes.forOwner(RecordOwner.paraLectura(userId))).length;
    final r = await _llamar(
        'El resumen de inicio',
        () async =>
            (await _api.get('/yo/inicio')) ?? const <String, dynamic>{});
    final tecnico = r['tecnico'] as Map<String, dynamic>?;
    return HomeSummary(
      date: DateTime.tryParse(r['fecha'] as String? ?? '') ?? DateTime.now(),
      // Solo si el servidor los envía (bloque `tecnico`); si no, la pantalla muestra «—».
      assignedLots: tecnico == null ? null : _int(tecnico['lotes_asignados']),
      pendingVisits:
          tecnico == null ? null : _int(tecnico['actividades_pendientes']),
      nextVisitTime: _hora(_fecha(tecnico?['proxima_actividad'])),
      lastSync: _fecha(tecnico?['ultima_sincronizacion']),
      unreadNotifications: _int(r['notificaciones_no_leidas']),
      pendingLocal: locales,
    );
  }

  @override
  Future<DateTime> syncNow() async {
    if (!AppServices.isOnline.value) {
      throw const OfflineException(
          'Sin conexión. Lo registrado sigue guardado en este teléfono.');
    }
    throw const NotAvailableYet(
      'El servidor todavía no recibe sincronizaciones. Lo registrado sigue guardado en este teléfono.',
    );
  }
}

/* ============================================================== lotes, trampas, mapa */

class ApiLotsRepository implements LotsRepository {
  ApiLotsRepository(this._api);
  final ApiClient _api;

  /// Estado del lote en la jornada (pendiente / en curso / visitado). La BD no lo guarda:
  /// se deriva de las visitas. Mientras la visita no se envía, vive en el teléfono.
  final _jornada = <String, LotStatus>{};

  Lot _conJornada(Lot l) =>
      _jornada[l.id] == null ? l : l.copyWith(status: _jornada[l.id]);

  @override
  Future<List<Lot>> getAssignedLots(String userId) =>
      _llamar('Los lotes asignados', () async {
        final filas = await _api.getList('/lotes');
        return [for (final f in filas) _conJornada(lotFromApi(f))];
      });

  @override
  Future<Lot> getLot(String lotId) => _llamar('El lote', () async {
        final f = await _api.get('/lotes/${Uri.encodeComponent(lotId)}');
        if (f == null) throw const DataException('Lote no encontrado.');
        return _conJornada(lotFromApi(f));
      });

  @override
  Future<List<Trap>> getTraps(String lotId) =>
      _llamar('Las trampas del lote', () async {
        final filas = await _api.getList('/trampas', query: {'lote_id': lotId});
        return [for (final f in filas) trapFromApi(f)];
      });

  @override
  Future<void> updateLotStatus(String lotId, LotStatus status) async =>
      _jornada[lotId] = status;
}

class ApiTrapsRepository implements TrapsRepository {
  ApiTrapsRepository(this._api);
  final ApiClient _api;

  @override
  Future<TrapLookup?> findByCode(String code, {String? activeLotId}) =>
      _llamar('La búsqueda de trampas', () async {
        try {
          final r = await _api.get(
              '/trampas/codigo/${Uri.encodeComponent(code.trim())}',
              query: {'lote_activo': activeLotId});
          final t = r?['trampa'] as Map<String, dynamic>?;
          if (r == null || t == null) return null;
          return TrapLookup(
            trap: trapFromApi(t),
            belongsToActiveLot: r['pertenece_lote_activo'] as bool? ?? true,
            insideLot: r['dentro_del_lote'] as bool?,
            inCatalog: r['en_catalogo'] as bool? ?? true,
          );
        } on ApiException catch (e) {
          if (e.status == 404) return null; // código que no está en el catálogo
          rethrow;
        }
      });
}

class ApiMapRepository implements MapRepository {
  ApiMapRepository(this._api);
  final ApiClient _api;

  /// La app todavía no guarda mosaicos sin conexión: nada está descargado.
  @override
  Future<bool> isMapDownloaded(String predioId) async => false;

  @override
  Future<void> downloadMap(String predioId,
      {void Function(double progress)? onProgress}) async {
    if (!AppServices.isOnline.value) {
      throw const OfflineException(
          'Necesitas conexión a internet para descargar el mapa.');
    }
    // Paquete de campo del predio (geometrías, trampas y mosaico). Hoy responde 501.
    await _llamar(
        'El mapa del predio',
        () => _api
            .get('/predios/${Uri.encodeComponent(predioId)}/paquete-campo'));
    throw const NotAvailableYet(
        'La descarga del mapa para trabajar sin conexión todavía no está disponible.');
  }
}

/* ============================================================== lecturas y sincronización */

class ApiReadingsRepository implements ReadingsRepository {
  ApiReadingsRepository(this._pendientes);
  final PendingStore _pendientes;

  /// La lectura se guarda en el TELÉFONO (funciona sin conexión) y queda pendiente de enviar.
  @override
  Future<void> saveReading(Reading reading) async {
    // Sin sesión válida no se toca la cola (ni para borrar la lectura anterior).
    final dueno = RecordOwner.requerido();
    // Reemplaza una lectura anterior de la misma trampa en esta visita (y su justificación).
    for (final p in await _pendientes.forOwner(dueno)) {
      if ((p.kind == PendingKind.lectura ||
              p.kind == PendingKind.justificacion) &&
          p.lotId == reading.lotId &&
          p.payload['trap_id'] == reading.trapId) {
        await _pendientes.remove(p.id);
      }
    }
    await _pendientes.put(PendingRecord(
      id: reading.id,
      ownerId: dueno,
      kind: PendingKind.lectura,
      label:
          '${reading.trapLabel} · ${reading.condition.wasRead ? '${reading.specimens} moscas' : 'no leída'}',
      observedAt: reading.observedAt,
      payload: reading.toJson(),
      lotId: reading.lotId,
    ));
  }

  @override
  Future<void> justifyTrap(
      {required String trapId,
      required String lotId,
      required String reason,
      String? visitId}) async {
    final ahora = DateTime.now();
    await _pendientes.put(PendingRecord(
      id: 'just-$lotId-$trapId',
      ownerId: RecordOwner.requerido(),
      kind: PendingKind.justificacion,
      label: 'Trampa no registrada · $reason',
      observedAt: ahora,
      payload: {
        'trap_id': trapId,
        'lot_id': lotId,
        'visit_id': visitId,
        'reason': reason,
        'observed_at': ahora.toIso8601String()
      },
      lotId: lotId,
    ));
  }

  @override
  Future<void> saveFieldVisit({
    required String visiId,
    required String predioId,
    required String lotId,
    required DateTime startedAt,
    required String label,
  }) async {
    final dueno = RecordOwner.requerido();
    final instante = startedAt.toUtc().toIso8601String();
    await _pendientes.put(PendingRecord(
      id: visiId,
      ownerId: dueno,
      kind: PendingKind.visitaCampo,
      label: label,
      observedAt: startedAt,
      payload: {
        'visi_id': visiId,
        'pred_id': int.parse(predioId),
        'lote_ids': [int.parse(lotId)],
        'ruta_id': null,
        'inicio': instante,
        'fin': instante,
      },
      lotId: lotId,
    ));
  }

  /// Lecturas de este lote guardadas en el teléfono (todas pendientes de enviar).
  @override
  Future<List<Reading>> readingsForLot(String lotId) async => [
        for (final p in await _pendientes.forOwner(_yo))
          if (p.kind == PendingKind.lectura && p.lotId == lotId)
            Reading.fromJson(p.payload),
      ];
}

class ApiSyncRepository implements SyncRepository {
  ApiSyncRepository(this._api, this._pendientes);

  final ApiClient _api;
  final PendingStore _pendientes;

  SecureStore get _secure => _api.store;

  static const _maxLote = 200;
  static const _claveUltima = 'sigat.sync.ultima';

  static bool _esOperacion(PendingKind kind) =>
      kind == PendingKind.visitaCampo ||
      kind == PendingKind.lectura ||
      kind == PendingKind.justificacion;

  @override
  Future<List<SyncItem>> getPending() async => [
        for (final p in await _pendientes.forOwner(_yo))
          if (_esOperacion(p.kind))
            SyncItem(
              id: p.id,
              ownerId: p.ownerId,
              label: '${p.kind.label} · ${p.label}',
              observedAt: p.observedAt,
              lastError: p.lastError,
            ),
      ];

  @override
  Future<DateTime?> lastSync() async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(_claveUltima);
    return texto == null ? null : DateTime.tryParse(texto);
  }

  @override
  Future<SyncPushSummary> push() async {
    if (!AppServices.isOnline.value) {
      throw const OfflineException(
          'Sin conexión. Los datos siguen guardados en este teléfono.');
    }

    final todos = await _pendientes.forOwner(_yo);
    final dispId = await _dispositivo();

    final visitas = todos
        .where((p) => p.kind == PendingKind.visitaCampo)
        .toList()
      ..sort((a, b) => a.observedAt.compareTo(b.observedAt));
    final lecturas = todos
        .where((p) =>
            p.kind == PendingKind.lectura ||
            p.kind == PendingKind.justificacion)
        .toList()
      ..sort((a, b) => a.observedAt.compareTo(b.observedAt));

    var diferidas = 0;
    final enviables = <PendingRecord>[];
    for (final lectura in lecturas) {
      if (_visiIdDe(lectura) == null) {
        await _pendientes.put(lectura.withError(
            'La lectura no tiene una visita asociada. Abre el lote de nuevo y vuelve a guardarla.'));
        diferidas++;
      } else {
        enviables.add(lectura);
      }
    }

    final ordenados = <PendingRecord>[...visitas, ...enviables];
    var confirmadas = 0;
    var enRevision = 0;
    var rechazadas = 0;
    for (var i = 0; i < ordenados.length; i += _maxLote) {
      final fin =
          (i + _maxLote < ordenados.length) ? i + _maxLote : ordenados.length;
      final resumen = await _enviarLote(ordenados.sublist(i, fin), dispId);
      confirmadas += resumen.$1;
      enRevision += resumen.$2;
      rechazadas += resumen.$3;
    }

    await _guardarUltima(DateTime.now());
    return SyncPushSummary(
      confirmadas: confirmadas,
      enRevision: enRevision,
      rechazadas: rechazadas,
      diferidas: diferidas,
    );
  }

  @override
  Future<List<ServerOperation>> inbox() =>
      _llamar('La bandeja de revisión', () async {
        final filas = await _api.getList('/sincronizacion/operaciones');
        return [for (final f in filas) ServerOperation.fromJson(f)];
      });

  Future<(int, int, int)> _enviarLote(
      List<PendingRecord> lote, String dispId) async {
    final ahora = DateTime.now();
    final operaciones = <Map<String, dynamic>>[];
    final porCliente = <String, PendingRecord>{};

    for (final registro in lote) {
      final operacion = _operacion(registro, dispId, ahora);
      porCliente[operacion['cliente_id'] as String] = registro;
      operaciones.add(operacion);
    }

    final respuesta = await _llamar('La sincronización', () async {
      return await _api.post('/sincronizacion/lotes', body: {
        'disp_id': dispId,
        'enviado_en': ahora.toUtc().toIso8601String(),
        'operaciones': operaciones,
      });
    });
    if (respuesta == null) {
      throw const DataException('El servidor devolvió una respuesta vacía.');
    }

    var confirmadas = 0;
    var enRevision = 0;
    var rechazadas = 0;
    for (final fila in (respuesta['resultados'] as List? ?? const [])) {
      if (fila is! Map) continue;
      final clienteId = fila['cliente_id']?.toString() ?? '';
      final registro = porCliente[clienteId];
      if (registro == null) continue;
      final resultado = fila['resultado']?.toString() ?? '';
      final motivo = fila['motivo']?.toString() ??
          fila['codigo']?.toString() ??
          'El servidor no aplicó la operación.';

      if (resultado.startsWith('alta_') ||
          resultado == 'correccion' ||
          resultado == 'idempotente_repetida') {
        await _pendientes.remove(registro.id);
        confirmadas++;
      } else {
        await _pendientes.put(registro.withError(motivo));
        if (resultado == 'revisar') {
          enRevision++;
        } else {
          rechazadas++;
        }
      }
    }
    return (confirmadas, enRevision, rechazadas);
  }

  Map<String, dynamic> _operacion(
      PendingRecord registro, String dispId, DateTime ahora) {
    final registroId = _registroIdDe(registro);
    final clienteId =
        CanonicalJson.uuidDesdeSemilla('cliente:$dispId:$registroId');
    final linaje = registro.kind == PendingKind.visitaCampo ? null : _linaje;
    final tObservacion = CanonicalJson.instanteCanonico(registro.observedAt);
    final datos = _datosDe(registro);

    final contenido = <String, dynamic>{
      'entidad': registro.kind.entity,
      'accion': 'crear',
      'registro_id': registroId,
      'version': 1,
      'linaje': linaje,
      't_observacion': tObservacion,
      'datos': datos,
    };
    final captura =
        ahora.isBefore(registro.observedAt) ? registro.observedAt : ahora;

    return {
      'cliente_id': clienteId,
      'entidad': registro.kind.entity,
      'accion': 'crear',
      'registro_id': registroId,
      'version': 1,
      'linaje': linaje,
      't_observacion': tObservacion,
      't_captura': captura.toUtc().toIso8601String(),
      'deriva_reloj_seg': null,
      'confirma_deriva_reloj': false,
      'hash_contenido': CanonicalJson.sha256Hex(contenido),
      'datos': datos,
    };
  }

  String _registroIdDe(PendingRecord registro) {
    if (registro.kind == PendingKind.visitaCampo) return registro.id;
    return CanonicalJson.uuidDesdeSemilla(
        'registro:${registro.ownerId}:${registro.kind.name}:${registro.id}');
  }

  String get _linaje => AppServices.session.value?.role == UserRole.productor
      ? 'autorreporte'
      : 'inspeccion_oficial';

  String? _visiIdDe(PendingRecord registro) {
    if (registro.kind == PendingKind.visitaCampo) return registro.id;
    if (registro.kind == PendingKind.lectura) {
      return Reading.fromJson(registro.payload).visitId;
    }
    if (registro.kind == PendingKind.justificacion) {
      return registro.payload['visit_id'] as String?;
    }
    return null;
  }

  Map<String, dynamic> _datosDe(PendingRecord registro) {
    switch (registro.kind) {
      case PendingKind.visitaCampo:
        final p = registro.payload;
        return {
          'pred_id': p['pred_id'],
          'lote_ids': p['lote_ids'],
          'ruta_id': p['ruta_id'],
          'visi_t_inicio_obs': p['inicio'],
          'visi_t_fin_obs': p['fin'],
        };
      case PendingKind.lectura:
        return Reading.fromJson(registro.payload).toSyncDatos();
      case PendingKind.justificacion:
        final p = registro.payload;
        return {
          'visi_id': p['visit_id'],
          'tram_id': int.parse(p['trap_id'].toString()),
          'lect_leida': false,
          'lect_especimenes': null,
          'lect_justificacion': p['reason'] ?? 'Trampa no leída',
          'cond_id': 2,
          'lect_observaciones': p['reason'],
        };
      default:
        throw const DataException(
            'Este tipo de registro todavía no se sincroniza desde el móvil.');
    }
  }

  Future<String> _dispositivo() async {
    final guardado = await _secure.deviceId;
    if (guardado != null && guardado.isNotEmpty) return guardado;
    final nuevo = CanonicalJson.generarUuidV4();
    await _secure.saveDeviceId(nuevo);
    return nuevo;
  }

  Future<void> _guardarUltima(DateTime instante) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_claveUltima, instante.toUtc().toIso8601String());
  }
}

class ApiHistoryRepository implements HistoryRepository {
  ApiHistoryRepository(this._api, this._pendientes);
  final ApiClient _api;
  final PendingStore _pendientes;

  /// Visitas del servidor (confirmadas) + visitas terminadas en este teléfono (pendientes).
  /// Si el servidor no responde y hay visitas locales, se muestran solo esas, marcadas como
  /// pendientes; si no hay nada local, se muestra el error.
  @override
  Future<List<VisitRecord>> getVisits() async {
    final locales = [
      for (final p in await _pendientes.forOwner(_yo))
        if (p.kind == PendingKind.visita) VisitRecord.fromJson(p.payload),
    ];
    List<VisitRecord> servidor;
    try {
      servidor = await _llamar('El historial de visitas', () async {
        final r = await _api.get('/visitas');
        return [
          for (final v in (r?['items'] as List? ?? const []))
            VisitRecord.fromApi(Map<String, dynamic>.from(v as Map)),
        ];
      });
    } on DataException {
      if (locales.isEmpty) rethrow;
      servidor = const [];
    }
    final ids = servidor.map((v) => v.id).toSet();
    return [...servidor, ...locales.where((v) => !ids.contains(v.id))]
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<void> saveVisit(VisitRecord visit) async =>
      _pendientes.put(PendingRecord(
        id: visit.id,
        ownerId: RecordOwner.requerido(),
        kind: PendingKind.visita,
        label: '${visit.lotsDone} de ${visit.lotsTotal} lotes',
        observedAt: visit.date,
        payload: visit.toJson(),
      ));
}

/* ============================================================== productor */

class ApiProducerRepository implements ProducerRepository {
  ApiProducerRepository(this._api, this._pendientes);
  final ApiClient _api;
  final PendingStore _pendientes;

  @override
  Future<CropSummary> getCropSummary(String userId) =>
      _llamar('El estado de tu cultivo', () async {
        final r = await _api.get('/productor/cultivo') ?? const {};
        final lotes = (r['lotes'] as List? ?? const []).cast<Map>();
        final activa = r['vigilancia_activa'] as bool? ?? false;
        return CropSummary(
          crop: r['cultivo'] as String? ?? 'Sin definir',
          lotLabel: lotes.length == 1
              ? lotes.first['lote_descripcion'] as String
              : '${lotes.length} lotes',
          vigilanceActive: activa,
          cropStatus: activa ? 'Activa' : 'Sin vigilancia',
          lotsReviewed: _int(r['lotes_revisados']),
          lastVisit: _fecha(r['ultima_visita']),
          lastMtd: _num(r['ultimo_mtd']),
          lastApplication: _fecha(r['ultima_aplicacion']),
        );
      });

  @override
  Future<void> saveApplication(PhytoApplication application) async =>
      _pendientes.put(PendingRecord(
        id: application.id,
        ownerId: RecordOwner.requerido(),
        kind: PendingKind.aplicacion,
        label: application.product,
        observedAt: application.date,
        payload: application.toJson(),
      ));

  @override
  Future<void> saveHarvest(HarvestReport harvest) async =>
      _pendientes.put(PendingRecord(
        id: harvest.id,
        ownerId: RecordOwner.requerido(),
        kind: PendingKind.cosecha,
        label: '${harvest.volumeKg} kg',
        observedAt: DateTime.now(),
        payload: harvest.toJson(),
      ));

  /// Actividad del servidor + autorreportes guardados en el teléfono (marcados como pendientes).
  @override
  Future<List<ActivityRecord>> getActivity(String userId) async {
    final locales = <ActivityRecord>[
      for (final p
          in await _pendientes.forOwner(RecordOwner.paraLectura(userId)))
        if (p.kind == PendingKind.aplicacion)
          ActivityRecord(
            id: p.id,
            type: ActivityType.aplicacion,
            date: p.observedAt,
            title: 'Aplicación · ${p.label}',
            subtitle: _pendienteDeEnviar,
          )
        else if (p.kind == PendingKind.cosecha)
          ActivityRecord(
            id: p.id,
            type: ActivityType.cosecha,
            date: p.observedAt,
            title: 'Cosecha · ${p.label}',
            subtitle: _pendienteDeEnviar,
          ),
    ];
    List<ActivityRecord> servidor;
    try {
      servidor = await _llamar('Tu historial', () async {
        final r = await _api.get('/actividad');
        return [
          for (final a in (r?['items'] as List? ?? const []))
            activityFromApi(Map<String, dynamic>.from(a as Map))
        ];
      });
    } on DataException {
      if (locales.isEmpty) rethrow;
      servidor = const [];
    }
    return [...servidor, ...locales]..sort((a, b) => b.date.compareTo(a.date));
  }
}

/// `EntradaActividad` (GET /actividad, GET /lotes/{id}/historial).
ActivityRecord activityFromApi(Map<String, dynamic> j) {
  final tipo = j['tipo'] as String? ?? '';
  final autor = j['autor'] as String? ?? '';
  final oficial = j['linaje'] == 'inspeccion_oficial';
  return ActivityRecord(
    id: j['registro_id'].toString(),
    type: tipo == 'aplicacion'
        ? ActivityType.aplicacion
        : tipo == 'cosecha'
            ? ActivityType.cosecha
            : ActivityType.vigilancia,
    date: _fecha(j['t_observacion']) ?? DateTime.now(),
    title: j['titulo'] as String? ?? '',
    subtitle: [
      if (j['detalle'] != null) j['detalle'] as String,
      if (autor.isNotEmpty)
        '${oficial ? 'Inspección oficial' : 'Autorreporte'} · $autor',
    ].join(' · '),
  );
}

/* ============================================================== perfil */

class ApiProfileRepository implements ProfileRepository {
  ApiProfileRepository(this._api);
  final ApiClient _api;

  /// Foto elegida en este teléfono y aún no enviada (se pierde al cerrar la app).
  final _fotoLocal = <String, UserProfile>{};

  @override
  Future<UserProfile> getProfile(String userId) =>
      _llamar('Tu perfil', () async {
        final r = await _api.get('/yo/perfil') ?? const {};
        final url = r['foto_url'] as String?;
        // Solo la foto local del usuario de la sesión (nunca la de otra cuenta).
        final local = _fotoLocal[RecordOwner.paraLectura(userId)];
        return UserProfile(
          userId: r['usua_id']?.toString() ?? userId,
          photoRemoteRef: url,
          photoStatus: local?.photoStatus ??
              (url == null ? null : UploadStatus.uploaded),
          photoBytes: local?.photoBytes,
          photoLocalPath: local?.photoLocalPath,
          // Sin preferencias guardadas el servidor envía todos los avisos (así funciona hoy).
          notifications: const NotificationPreferences(),
        );
      });

  @override
  Future<UserProfile> saveProfilePhotoLocally(
      String userId, PhotoFile photo) async {
    final yo = RecordOwner.exigirMismoUsuario(userId);
    final base = _fotoLocal[yo] ?? UserProfile(userId: yo);
    return _fotoLocal[yo] = base.copyWith(
      photoBytes: photo.bytes,
      photoLocalPath: photo.path,
      photoStatus: UploadStatus.local,
    );
  }

  @override
  Future<UserProfile> removeProfilePhoto(String userId) async {
    final yo = RecordOwner.exigirMismoUsuario(userId);
    _fotoLocal.remove(yo);
    return UserProfile(userId: yo);
  }

  /// FALTA EN EL BACKEND: `POST /archivos` (URL firmada) y `PUT /yo/perfil/foto` (501).
  @override
  Future<String> uploadProfilePhoto(String userId, PhotoFile photo) async {
    throw const BackendNotAvailable(
      'La foto quedó guardada en este teléfono. El servidor todavía no recibe fotos de perfil.',
    );
  }

  /// FALTA EN EL BACKEND: `PUT /yo/preferencias-notificacion` (501).
  @override
  Future<NotificationPreferences> updateNotifications(
      String userId, NotificationPreferences prefs) async {
    try {
      await _api.put('/yo/preferencias-notificacion', body: {
        'categorias': {
          for (final c in NotificationCategory.values)
            _codigo(c): prefs.categories[c] ?? prefs.enabled
        },
      });
      return prefs;
    } on ApiException catch (e) {
      if (e.isNotImplemented) {
        throw const BackendNotAvailable(
            'El servidor todavía no guarda tus preferencias de avisos.');
      }
      throw BackendNotAvailable(e.detail);
    }
  }

  static String _codigo(NotificationCategory c) => c.name
      .replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');
}

/* ============================================================== avisos (FUNCIONA) */

class ApiNotificationsRepository implements NotificationsRepository {
  ApiNotificationsRepository(this._api, {this.routeFor});
  final ApiClient _api;

  /// Traduce `destino.ruta` del backend a una pantalla de la app.
  final String? Function(String ruta)? routeFor;

  @override
  Future<List<AppNotification>> getForUser(String userId) =>
      _llamar('Tus avisos', () async {
        final r = await _api.get('/yo/notificaciones');
        return [
          for (final n in (r?['items'] as List? ?? const []))
            AppNotification.fromApi(Map<String, dynamic>.from(n as Map),
                userId: userId, routeFor: routeFor),
        ];
      });

  @override
  Future<int> unreadCount(String userId) => _llamar('Tus avisos', () async {
        final r = await _api.get('/yo/notificaciones/conteo');
        return _int(r?['no_leidas']);
      });

  @override
  Future<void> markAsRead(String userId, String notificationId) => _llamar(
      'Marcar el aviso',
      () => _api.post(
          '/yo/notificaciones/${Uri.encodeComponent(notificationId)}/leida'));

  @override
  Future<void> markAllAsRead(String userId) => _llamar(
      'Marcar los avisos', () => _api.post('/yo/notificaciones/leidas'));
}

/* ============================================================== planificación */

class ApiPlanningRepository implements PlanningRepository {
  ApiPlanningRepository(this._api, this._pendientes);
  final ApiClient _api;
  final PendingStore _pendientes;

  /// Nombre visible del lote → `lote_id` (de `GET /planificaciones/lotes-asignables`).
  final _idLote = <String, String>{};

  Future<List<Planning>> _bandeja(String bandeja) =>
      _llamar('Las planificaciones', () async {
        final r =
            await _api.get('/planificaciones', query: {'bandeja': bandeja});
        return [
          for (final p in (r?['items'] as List? ?? const []))
            Planning.fromApi(Map<String, dynamic>.from(p as Map))
        ];
      });

  @override
  Future<List<Planning>> getReceived(String userId) => _bandeja('recibidas');

  @override
  Future<List<Planning>> getCreated() => _bandeja('creadas');

  @override
  Future<List<Recipient>> getRecipients(PlanningTarget target) =>
      _llamar('Los destinatarios', () async {
        final filas = await _api.getList('/planificaciones/destinatarios',
            query: {'tipo': target.name});
        return [
          for (final f in filas)
            Recipient(
                id: f['usua_id'].toString(),
                name: f['nombre'] as String,
                target: target),
        ];
      });

  @override
  Future<List<String>> getAssignableLots() =>
      _llamar('Los lotes asignables', () async {
        final filas = await _api.getList('/planificaciones/lotes-asignables');
        return [
          for (final f in filas) _nombreLote(f),
        ];
      });

  String _nombreLote(Map<String, dynamic> f) {
    final nombre =
        '${f['pred_nombre']} · ${f['lote_descripcion'] ?? 'Lote ${f['lote_codigo']}'}';
    _idLote[nombre] = f['lote_id'].toString();
    return nombre;
  }

  @override
  Future<Planning> create(Planning planning) =>
      _llamar('Crear la planificación', () async {
        if (planning.doc != null) {
          // FALTA EN EL BACKEND: POST /archivos (URL firmada) para subir el documento.
          throw const NotAvailableYet(
              'La subida del documento de instrucciones todavía no está disponible.');
        }
        String? hhmm(String? v) => v == null ? null : '$v:00';
        final r = await _api.post('/planificaciones', body: {
          'usua_id_destinatario': int.parse(planning.recipientId),
          'plan_actividad': planning.activity,
          'plan_fecha_inicio':
              planning.startDate.toIso8601String().substring(0, 10),
          'plan_fecha_fin':
              planning.endDate?.toIso8601String().substring(0, 10),
          'plan_hora_desde': hhmm(planning.scheduleFrom),
          'plan_hora_hasta': hhmm(planning.scheduleTo),
          'plan_observaciones': planning.observations,
          'plan_id_origen': planning.originId,
          'lote_ids': [
            for (final n in planning.lotNames)
              if (_idLote[n] != null) int.parse(_idLote[n]!)
          ],
        });
        return Planning.fromApi(r ?? const {});
      });

  @override
  Future<Planning> accept(String planningId) =>
      _llamar('Aceptar la planificación', () async {
        final r = await _api.post(
            '/planificaciones/${Uri.encodeComponent(planningId)}/aceptacion',
            body: const {});
        return Planning.fromApi(r ?? const {});
      });

  @override
  Future<Planning> reject(String planningId, String reason) =>
      _llamar('Rechazar la planificación', () async {
        if (reason.trim().isEmpty) {
          throw const DataException('Escribe el motivo del rechazo.');
        }
        final r = await _api.post(
            '/planificaciones/${Uri.encodeComponent(planningId)}/rechazo',
            body: {'motivo': reason.trim()});
        return Planning.fromApi(r ?? const {});
      });

  @override
  Future<Planning> reportLotResult(String planningId, String lotName,
          {required bool executed, String? justification}) =>
      _llamar('Registrar el resultado del lote', () async {
        if (!executed && (justification ?? '').trim().isEmpty) {
          throw const DataException('Escribe por qué no se ejecutó.');
        }
        final loteId = _idLote[lotName];
        if (loteId == null) {
          throw const DataException(
              'No se reconoce el lote de esta actividad.');
        }
        final r = await _api.post(
          '/planificaciones/${Uri.encodeComponent(planningId)}/lotes/$loteId/resultado',
          body: {
            'plal_estado': executed ? 'ejecutada' : 'no_ejecutada',
            'plal_observacion': justification
          },
        );
        return Planning.fromApi(r ?? const {});
      });

  /// Se llama al terminar la visita de un lote (puede ser sin conexión): queda en el
  /// teléfono como pendiente y viaja con la sincronización (entidad `planificacion_lote`).
  @override
  Future<void> markLotExecutedForUser(String userId, String lotName) async {
    // Solo el usuario de la sesión puede dejar el resultado a su nombre.
    final dueno = RecordOwner.exigirMismoUsuario(userId);
    await _pendientes.put(PendingRecord(
      id: 'plal-$dueno-$lotName-${DateTime.now().toIso8601String().substring(0, 10)}',
      ownerId: dueno,
      kind: PendingKind.resultadoLote,
      label: '$lotName · ejecutado',
      observedAt: DateTime.now(),
      payload: {'lot_name': lotName, 'plal_estado': 'ejecutada'},
    ));
  }
}

/* ============================================================== agrónomo */

/// `Lectura` (GET /lecturas): ya está en el servidor ([Reading.synced] = true).
Reading readingFromApi(Map<String, dynamic> j) {
  final leida = j['lect_leida'] as bool? ?? true;
  final codigo = j['tram_codigo']?.toString() ?? '';
  return Reading(
    id: j['lect_registro_id'].toString(),
    trapId: j['tram_id'].toString(),
    trapLabel:
        codigo.isEmpty ? '' : 'ICA-${codigo.split('-').last.padLeft(3, '0')}',
    lotId: j['lote_id'].toString(),
    observedAt: _fecha(j['t_observacion']) ?? DateTime.now(),
    specimens: _int(j['lect_especimenes']),
    condition: !leida
        ? TrapCondition.noEncontrada
        : (_int(j['cond_id']) == 2
            ? TrapCondition.danada
            : TrapCondition.buenEstado),
    bodyChangeDate: _fecha(j['lect_fecha_cambio_cuerpo']),
    attractantChangeDate: _fecha(j['lect_fecha_cambio_atrayente']),
    observations:
        (j['lect_observaciones'] ?? j['lect_justificacion']) as String?,
    synced: true,
  );
}

RecordReviewStatus _estadoRevision(String? v) => switch (v) {
      'aceptado' => RecordReviewStatus.aceptado,
      'en_revision' => RecordReviewStatus.enRevision,
      _ => RecordReviewStatus.pendiente,
    };

/// `RegistroRevision` / `RevisionDetalle`.
FieldRecord fieldRecordFromApi(Map<String, dynamic> j) {
  final lotes = [
    for (final l in (j['lotes'] as List? ?? const [])) l.toString()
  ];
  return FieldRecord(
    id: j['visi_id'].toString(),
    technicianName: j['tecnico'] as String? ?? '',
    observedAt: _fecha(j['observada_el']) ?? DateTime.now(),
    receivedAt: _fecha(j['recibida_el']) ?? DateTime.now(),
    lotsVisited: lotes.length,
    trapsTotal: _int(j['trampas_leidas']),
    lotIds: lotes,
    reviewReason: j['motivo_revision'] as String?,
    status: _estadoRevision(j['estado_revision'] as String?),
  );
}

String _concepto(String? v) => switch (v) {
      'apto' => 'Apto',
      'no_apto' => 'No apto',
      _ => 'No emitido',
    };

/// `ResumenLote` (GET /lotes/{id}/resumen). Todo lo calcula el servidor.
LotSummary lotSummaryFromApi(Map<String, dynamic> j) {
  final etapa = j['etapa'] as Map<String, dynamic>? ?? const {};
  final serie = [
    for (final p in (j['serie'] as List? ?? const []))
      if (_num((p as Map)['mtd']) != null)
        MtdPoint(DateTime.parse(p['peri_fin'] as String), _num(p['mtd'])!),
  ];
  return LotSummary(
    lotId: j['lote_id'].toString(),
    lotName: j['lote_descripcion'] as String? ?? '',
    scenario: j['escenario'] as String? ?? 'Sin definir',
    mtd: _num(j['mtd']),
    exportThreshold: j['umbral']?.toString() ?? 'Sin definir',
    aptitudeConcept: _concepto(j['concepto'] as String?),
    series: serie,
    scenarioLimit: _num(j['umbral']) ?? 0,
    inspectionsThisMonth: _int(j['inspecciones_mes']),
    applications: _int(j['aplicaciones']),
    lastApplication: _fecha(j['ultima_aplicacion']),
    trapsTotal: _int(j['trampas_vigentes']),
    lastVisit: _fecha(j['ultima_visita']),
    readingsTotal: _int(j['lecturas']),
    specimensDetected: _int(j['especimenes']),
    trapsWithFindings: _int(j['trampas_con_capturas']),
    phenologicalStage:
        (etapa['declarada'] ?? etapa['derivada'] ?? 'Sin definir') as String,
    estimatedYieldKg: _num(j['rendimiento_estimado']),
    actualYieldKg: _num(j['rendimiento_real']),
    goodPracticesLabel: 'Sin dato del servidor',
    activeFindings: _int(j['hallazgos']),
    pendingReviewLabel: j['revision_pendiente'] as String?,
    expectedHarvest: _fecha(j['cosecha_esperada']),
  );
}

/// `ProgramaInspeccion` (GET /lotes/{id}/programa) + número de trampas del lote.
InspectionConfig inspectionConfigFromApi(Map<String, dynamic> j,
    {required int traps}) {
  final umbral = j['umbral_exportacion_mtd']?.toString();
  return InspectionConfig(
    readingPeriodDays: _int(j['periodo_lectura_dias']),
    trapsConfigured: traps,
    verification: (j['norma'] as Map?)?['norm_titulo'] as String? ??
        'Sin norma registrada',
    scenarios: [
      for (final e in (j['escenarios'] as List? ?? const []))
        TrappingScenario(
          name: (e as Map)['descripcion'] as String,
          rule: e['mtd_hasta'] == null
              ? 'MTD desde ${e['mtd_desde']}'
              : 'MTD entre ${e['mtd_desde']} y ${e['mtd_hasta']}',
        ),
      TrappingScenario(
        name: 'Umbral de exportación',
        rule: umbral == null ? 'MTD sin definir' : 'MTD $umbral',
        pending: umbral == null,
      ),
    ],
  );
}

class ApiAgronomistRepository implements AgronomistRepository {
  ApiAgronomistRepository(this._api);
  final ApiClient _api;

  @override
  Future<List<FieldRecord>> getPendingRecords() =>
      _llamar('Los registros por revisar', () async {
        final r = await _api.get('/revisiones');
        return [
          for (final x in (r?['items'] as List? ?? const []))
            fieldRecordFromApi(Map<String, dynamic>.from(x as Map)),
        ].where((f) => f.status != RecordReviewStatus.aceptado).toList();
      });

  @override
  Future<FieldRecord> getRecord(String recordId) =>
      _llamar('El registro', () async {
        final r =
            await _api.get('/revisiones/${Uri.encodeComponent(recordId)}');
        if (r == null) throw const DataException('Registro no encontrado.');
        return fieldRecordFromApi(r);
      });

  @override
  Future<FieldRecord> acceptRecord(String recordId) =>
      _llamar('Aceptar el registro', () async {
        final r = await _api
            .post('/revisiones/${Uri.encodeComponent(recordId)}/aceptacion');
        return fieldRecordFromApi(r ?? const {});
      });

  @override
  Future<LotSummary> getLotSummary(String lotId) =>
      _llamar('El resumen del lote', () async {
        final r =
            await _api.get('/lotes/${Uri.encodeComponent(lotId)}/resumen');
        return lotSummaryFromApi(r ?? const {});
      });

  @override
  Future<List<ActivityRecord>> getLotHistory(String lotId) =>
      _llamar('El historial del lote', () async {
        final r =
            await _api.get('/lotes/${Uri.encodeComponent(lotId)}/historial');
        return [
          for (final a in (r?['items'] as List? ?? const []))
            activityFromApi(Map<String, dynamic>.from(a as Map))
        ];
      });

  @override
  Future<(Trap, Reading?)> trapWithLastReading(String trapId) =>
      _llamar('La lectura de la trampa', () async {
        final t = await _api.get('/trampas/${Uri.encodeComponent(trapId)}');
        if (t == null) throw const DataException('Trampa no encontrada.');
        final r = await _api.get('/lecturas', query: {'tram_id': trapId});
        final items = [
          for (final x in (r?['items'] as List? ?? const []))
            Map<String, dynamic>.from(x as Map)
        ];
        items.removeWhere((x) => x['anulada'] == true);
        items.sort((a, b) => (a['t_observacion'] as String)
            .compareTo(b['t_observacion'] as String));
        return (
          trapFromApi(t),
          items.isEmpty ? null : readingFromApi(items.last)
        );
      });

  @override
  Future<InspectionConfig> getInspectionConfig(String lotId) =>
      _llamar('El programa de inspección', () async {
        final r =
            await _api.get('/lotes/${Uri.encodeComponent(lotId)}/programa');
        final trampas =
            await _api.getList('/trampas', query: {'lote_id': lotId});
        return inspectionConfigFromApi(r ?? const {}, traps: trampas.length);
      });
}
