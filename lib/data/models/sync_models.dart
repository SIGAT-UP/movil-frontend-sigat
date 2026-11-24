class SyncPushSummary {
  const SyncPushSummary({
    this.confirmadas = 0,
    this.enRevision = 0,
    this.rechazadas = 0,
    this.diferidas = 0,
  });

  final int confirmadas;
  final int enRevision;
  final int rechazadas;
  final int diferidas;

  int get enviadas => confirmadas + enRevision + rechazadas;
  bool get hayPendientes => enRevision > 0 || rechazadas > 0 || diferidas > 0;
}

class ServerOperation {
  const ServerOperation({
    required this.operId,
    required this.entidad,
    required this.accion,
    required this.registroId,
    required this.version,
    required this.clasificacion,
    required this.capturadaEn,
    required this.recibidaEn,
    this.motivo,
  });

  factory ServerOperation.fromJson(Map<String, dynamic> j) => ServerOperation(
        operId: (j['oper_id'] as num).toInt(),
        entidad: j['entidad']?.toString() ?? '',
        accion: j['accion']?.toString() ?? '',
        registroId: j['registro_id']?.toString() ?? '',
        version: (j['version'] as num?)?.toInt() ?? 1,
        clasificacion: j['clasificacion']?.toString() ?? 'revisar',
        motivo: j['motivo'] as String?,
        capturadaEn: _fecha(j['t_captura']),
        recibidaEn: _fecha(j['t_recepcion']),
      );

  final int operId;
  final String entidad;
  final String accion;
  final String registroId;
  final int version;
  final String clasificacion;
  final String? motivo;
  final DateTime capturadaEn;
  final DateTime recibidaEn;

  bool get esVisita => entidad == 'visita';
  bool get enRevision => clasificacion == 'revisar';

  String get titulo => switch ((entidad, accion)) {
        ('visita', _) => 'Visita de campo',
        ('lectura_trampa', 'anular') => 'Anulación de lectura',
        ('lectura_trampa', 'corregir') => 'Corrección de lectura',
        ('lectura_trampa', _) => 'Lectura de trampa',
        _ => entidad,
      };

  String get estado => enRevision ? 'Por revisar' : 'Rechazada';

  ServerOperation copyWith({String? clasificacion, String? motivo}) =>
      ServerOperation(
        operId: operId,
        entidad: entidad,
        accion: accion,
        registroId: registroId,
        version: version,
        clasificacion: clasificacion ?? this.clasificacion,
        motivo: motivo ?? this.motivo,
        capturadaEn: capturadaEn,
        recibidaEn: recibidaEn,
      );
}

DateTime _fecha(dynamic v) => v == null
    ? DateTime.now()
    : DateTime.tryParse(v.toString())?.toLocal() ?? DateTime.now();
