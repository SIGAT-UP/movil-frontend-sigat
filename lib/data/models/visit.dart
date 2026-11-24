enum VisitStatus {
  enProgreso('En progreso'),

  /// Terminada y guardada en el teléfono; el servidor todavía no la confirmó.
  completada('Completada · pendiente de enviar'),

  /// El servidor la recibió.
  sincronizada('Sincronizada');

  const VisitStatus(this.label);
  final String label;
}

/// Registro del historial de visitas.
class VisitRecord {
  const VisitRecord({
    required this.id,
    required this.date,
    required this.lotsDone,
    required this.lotsTotal,
    required this.status,
    this.predioNombre,
    this.tecnico,
    this.lotes = const [],
    this.estadoRevision,
    this.motivoRevision,
    this.trampasLeidas,
    this.cachedAt,
  });

  final String id;
  final DateTime date;
  final int lotsDone;
  final int lotsTotal;
  final VisitStatus status;

  /// Predio de la visita (solo visitas del servidor).
  final String? predioNombre;
  final String? tecnico;

  /// Códigos de los lotes inspeccionados (`lotes` del contrato).
  final List<String> lotes;

  /// `estado_revision` del contrato (p. ej. `pendiente`, `aceptado`). null = aún no enviada.
  final String? estadoRevision;
  final String? motivoRevision;
  final int? trampasLeidas;

  /// Momento en que se guardó la copia que se muestra (null = datos en vivo).
  final DateTime? cachedAt;

  String get title => status == VisitStatus.enProgreso
      ? 'Visita en curso'
      : 'Visita completada';

  factory VisitRecord.fromJson(Map<String, dynamic> j) => VisitRecord(
        id: j['id'].toString(),
        date: DateTime.parse(j['date'] as String),
        lotsDone: j['lots_done'] as int,
        lotsTotal: j['lots_total'] as int,
        status: VisitStatus.values.firstWhere((s) => s.name == j['status'],
            orElse: () => VisitStatus.completada),
        lotes: [for (final l in (j['lotes'] as List? ?? const [])) '$l'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'lots_done': lotsDone,
        'lots_total': lotsTotal,
        'status': status.name,
        'lotes': lotes,
      };

  /// Visita que devuelve `GET /visitas` o `GET /visitas/{id}` (`Visita` del contrato).
  /// Ya está en el servidor. [cachedAt] marca una copia guardada sin red.
  factory VisitRecord.fromApi(Map<String, dynamic> j, {DateTime? cachedAt}) {
    final ids = (j['lote_ids'] as List?) ?? (j['lotes'] as List?) ?? const [];
    return VisitRecord(
      id: j['visi_id'].toString(),
      date: DateTime.parse((j['t_inicio_obs'] ?? j['t_captura']) as String),
      lotsDone: ids.length,
      lotsTotal: ids.length,
      status: VisitStatus.sincronizada,
      predioNombre: j['pred_nombre'] as String?,
      tecnico: j['tecnico'] as String?,
      lotes: [for (final l in (j['lotes'] as List? ?? const [])) '$l'],
      estadoRevision: j['estado_revision'] as String?,
      motivoRevision: j['motivo_revision'] as String?,
      trampasLeidas: j['trampas_leidas'] as int?,
      cachedAt: cachedAt,
    );
  }
}

/// Registro en la cola de sincronización (lecturas del técnico, autorreportes del productor).
class SyncItem {
  const SyncItem({
    required this.id,
    required this.ownerId,
    required this.label,
    required this.observedAt,
    this.synced = false,
    this.lastError,
  });

  final String id;

  /// Usuario dueño del registro: cada usuario solo ve y sincroniza lo suyo.
  final String ownerId;
  final String label; // "LOTE-A · ICA-001", "Aplicación fitosanitaria"
  final DateTime observedAt;

  /// true SOLO cuando el servidor confirmó que lo recibió.
  final bool synced;

  /// Por qué no se pudo enviar la última vez (sin conexión, servidor no disponible…).
  final String? lastError;

  /// Úselo SOLO cuando el servidor confirmó que recibió el registro.
  SyncItem markSynced() => SyncItem(
      id: id,
      ownerId: ownerId,
      label: label,
      observedAt: observedAt,
      synced: true);
}
