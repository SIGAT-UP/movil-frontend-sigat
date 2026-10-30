import 'dart:typed_data';

/// A quién va dirigida la planificación.
enum PlanningTarget {
  /// Asignación de lotes a un técnico (Agrónomo → Técnico).
  tecnico('Asignación de lotes'),

  /// Planeación de actividades para un productor (Agrónomo → Productor).
  productor('Planeación de actividades');

  const PlanningTarget(this.label);
  final String label;
}

/// Estado de una planificación (BD: `planificacion.plan_estado`).
///
/// El ciclo depende de quién la recibe (regla de la BD v7, `fn_planificacion_valida`):
///  * PRODUCTOR: pendiente → aceptada | rechazada (el motivo es obligatorio) → completada.
///  * TÉCNICO:   nace ya autorizada (pendiente) y pasa a completada cuando TODOS sus
///               lotes tienen resultado. El técnico NO acepta ni rechaza.
enum PlanningStatus {
  pendiente('Pendiente'),
  aceptada('Aceptada'),
  rechazada('Rechazada'),
  completada('Completada');

  const PlanningStatus(this.label);
  final String label;

  /// Solo se puede responder cuando está pendiente.
  bool get canRespond => this == pendiente;
}

/// Resultado de una actividad de técnico en un lote
/// (BD: `planificacion_lote.plal_estado`).
enum LotResult {
  pendiente('Pendiente', 'pendiente'),
  ejecutada('Ejecutada', 'ejecutada'),
  noEjecutada('No ejecutada', 'no_ejecutada');

  const LotResult(this.label, this.dbValue);
  final String label;

  /// Valor exacto que guarda la BD.
  final String dbValue;

  static LotResult fromDb(String? v) =>
      LotResult.values.firstWhere((r) => r.dbValue == v, orElse: () => LotResult.pendiente);
}

/// Tipo de archivo de instrucciones que puede adjuntar el agrónomo.
enum DocKind {
  pdf('PDF', 'application/pdf'),
  word('Word', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'),
  imagen('Imagen', 'image/jpeg');

  const DocKind(this.label, this.defaultMime);
  final String label;
  final String defaultMime;

  /// Deduce el tipo por la extensión. Solo se usa con datos que vienen del
  /// servidor; lo que elige el usuario se valida por su contenido.
  static DocKind fromFileName(String name) {
    final n = name.toLowerCase();
    if (n.endsWith('.doc') || n.endsWith('.docx')) return word;
    if (n.endsWith('.jpg') || n.endsWith('.jpeg') || n.endsWith('.png') || n.endsWith('.webp')) {
      return imagen;
    }
    return pdf;
  }
}

/// Documento de instrucciones adjunto a una planificación.
///
/// Dos orígenes:
///  * Elegido en ESTE dispositivo por el agrónomo: trae `bytes`, el contenido
///    real del archivo. Vive solo en memoria y NO se serializa: cuando exista
///    el servidor, se sube y aquí queda su identificador o URL.
///  * Llegado del servidor: sin `bytes`.
class PlanningDoc {
  const PlanningDoc({
    required this.id,
    required this.fileName,
    required this.sizeBytes,
    this.pages,
    this.kind = DocKind.pdf,
    this.mimeType,
    this.bytes,
    this.assetPath,
  });

  final String id;
  final String fileName;
  final int sizeBytes;

  /// Número de páginas si se conoce (solo PDF). null = desconocido.
  final int? pages;
  final DocKind kind;
  final String? mimeType;
  final Uint8List? bytes;
  final String? assetPath;

  /// Hay archivo real disponible en el dispositivo.
  bool get hasLocalFile => bytes != null;

  String get sizeLabel => sizeBytes >= 1024 * 1024
      ? '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',')} MB'
      : '${(sizeBytes / 1024).round()} KB';

  /// "8 páginas · 2,4 MB", "Documento Word · 340 KB", "Imagen · 1,2 MB".
  String get detailLabel => switch (kind) {
        DocKind.pdf => pages == null
            ? 'PDF · $sizeLabel'
            : '$pages ${pages == 1 ? 'página' : 'páginas'} · $sizeLabel',
        DocKind.word => 'Documento Word · $sizeLabel',
        DocKind.imagen => 'Imagen · $sizeLabel',
      };

  factory PlanningDoc.fromJson(Map<String, dynamic> j) {
    final name = j['file_name'] as String;
    final kindName = j['kind'] as String?;
    return PlanningDoc(
      id: j['id'].toString(),
      fileName: name,
      sizeBytes: j['size_bytes'] as int? ?? 0,
      pages: j['pages'] as int?,
      kind: DocKind.values.firstWhere(
        (k) => k.name == kindName,
        orElse: () => DocKind.fromFileName(name),
      ),
      mimeType: j['mime_type'] as String?,
    );
  }

  /// Los `bytes` no viajan aquí: el archivo se sube aparte (multipart).
  Map<String, dynamic> toJson() => {
        'id': id,
        'file_name': fileName,
        'size_bytes': sizeBytes,
        'pages': pages,
        'kind': kind.name,
        'mime_type': mimeType ?? kind.defaultMime,
      };
}

/// Planificación creada por el Agrónomo y dirigida a un técnico o a un productor.
///
/// Un solo modelo para los dos casos: cambian los campos que se llenan
/// (`lotNames` solo aplica al técnico), no el ciclo de estados.
class Planning {
  const Planning({
    required this.id,
    required this.target,
    required this.recipientId,
    required this.recipientName,
    required this.activity,
    required this.startDate,
    required this.createdAt,
    required this.createdByName,
    this.endDate,
    this.scheduleFrom,
    this.scheduleTo,
    this.lotNames = const [],
    this.observations,
    this.doc,
    this.status = PlanningStatus.pendiente,
    this.rejectionReason,
    this.respondedAt,
    this.originId,
    this.lotResults = const {},
    this.lotJustifications = const {},
  });

  final String id;
  final PlanningTarget target;

  /// Usuario que la recibe. El backend debe entregar solo las suyas.
  final String recipientId;
  final String recipientName;

  /// Actividad: "Muestreo de cultivos", "Revisión de trampas"...
  final String activity;

  final DateTime startDate;
  final DateTime? endDate;

  /// Horario opcional (ej. 08:00 – 16:00).
  final String? scheduleFrom;
  final String? scheduleTo;

  /// Lotes asignados. Solo se usa cuando [target] es técnico.
  final List<String> lotNames;

  final String? observations;
  final PlanningDoc? doc;

  final PlanningStatus status;

  /// Motivo que escribió quien la rechazó. Se conserva para que el Agrónomo
  /// pueda consultarlo y reprogramar.
  final String? rejectionReason;
  final DateTime? respondedAt;

  final DateTime createdAt;
  final String createdByName;

  /// BD `plan_id_origen`. Una actividad de técnico apunta a la planificación del
  /// productor YA ACEPTADA de la que sale; la del productor no tiene origen.
  final String? originId;

  /// Resultado por lote (clave = nombre del lote). Solo aplica al técnico.
  final Map<String, LotResult> lotResults;

  /// Justificación obligatoria de los lotes "no ejecutada".
  final Map<String, String> lotJustifications;

  /// Solo el PRODUCTOR acepta o rechaza, y solo mientras está pendiente.
  bool get recipientCanRespond => target == PlanningTarget.productor && status.canRespond;

  LotResult resultOf(String lotName) => lotResults[lotName] ?? LotResult.pendiente;

  /// Todos los lotes de la actividad de técnico ya tienen resultado.
  bool get allLotsResolved =>
      lotNames.isNotEmpty && lotNames.every((n) => resultOf(n) != LotResult.pendiente);

  /// Periodo legible: "15 nov - 22 dic · 7 días" o solo la fecha.
  int? get durationDays => endDate?.difference(startDate).inDays;

  Planning copyWith({
    PlanningStatus? status,
    String? rejectionReason,
    DateTime? respondedAt,
    bool clearRejection = false,
    Map<String, LotResult>? lotResults,
    Map<String, String>? lotJustifications,
  }) =>
      Planning(
        id: id,
        target: target,
        recipientId: recipientId,
        recipientName: recipientName,
        activity: activity,
        startDate: startDate,
        endDate: endDate,
        scheduleFrom: scheduleFrom,
        scheduleTo: scheduleTo,
        lotNames: lotNames,
        observations: observations,
        doc: doc,
        status: status ?? this.status,
        rejectionReason: clearRejection ? null : (rejectionReason ?? this.rejectionReason),
        respondedAt: respondedAt ?? this.respondedAt,
        createdAt: createdAt,
        createdByName: createdByName,
        originId: originId,
        lotResults: lotResults ?? this.lotResults,
        lotJustifications: lotJustifications ?? this.lotJustifications,
      );

  factory Planning.fromJson(Map<String, dynamic> j) => Planning(
        id: j['id'].toString(),
        target: PlanningTarget.values.firstWhere((t) => t.name == j['target'],
            orElse: () => PlanningTarget.tecnico),
        recipientId: j['recipient_id'].toString(),
        recipientName: j['recipient_name'] as String,
        activity: j['activity'] as String,
        startDate: DateTime.parse(j['start_date'] as String),
        endDate: j['end_date'] == null ? null : DateTime.parse(j['end_date'] as String),
        scheduleFrom: j['schedule_from'] as String?,
        scheduleTo: j['schedule_to'] as String?,
        lotNames: (j['lot_names'] as List?)?.cast<String>() ?? const [],
        observations: j['observations'] as String?,
        doc: j['doc'] == null ? null : PlanningDoc.fromJson(j['doc'] as Map<String, dynamic>),
        status: PlanningStatus.values.firstWhere((s) => s.name == j['status'],
            orElse: () => PlanningStatus.pendiente),
        rejectionReason: j['rejection_reason'] as String?,
        respondedAt: j['responded_at'] == null ? null : DateTime.parse(j['responded_at'] as String),
        createdAt: DateTime.parse(j['created_at'] as String),
        createdByName: j['created_by_name'] as String? ?? '',
        originId: j['origin_id']?.toString(),
        lotResults: ((j['lot_results'] as Map?) ?? const {})
            .map((k, v) => MapEntry(k as String, LotResult.fromDb(v as String?))),
        lotJustifications: ((j['lot_justifications'] as Map?) ?? const {}).cast<String, String>(),
      );

  /// Construye la planificación desde una fila de la vista `v_planificacion`
  /// (lo que devuelve `GET /plannings`). Los nombres son los de la BD.
  /// `lotes` llega como lista de códigos de lote; los resultados por lote se
  /// piden aparte (`lot_results`) cuando el backend los exponga.
  factory Planning.fromApi(Map<String, dynamic> j) {
    String? hhmm(dynamic v) => v == null ? null : (v as String).substring(0, 5);
    final rol = (j['rol_destinatario'] as String? ?? '').toLowerCase();
    return Planning(
      id: j['plan_id'].toString(),
      target: rol.startsWith('t') ? PlanningTarget.tecnico : PlanningTarget.productor,
      recipientId: j['usua_id_destinatario'].toString(),
      recipientName: j['destinatario'] as String,
      activity: j['plan_actividad'] as String,
      startDate: DateTime.parse(j['plan_fecha_inicio'] as String),
      endDate: j['plan_fecha_fin'] == null ? null : DateTime.parse(j['plan_fecha_fin'] as String),
      scheduleFrom: hhmm(j['plan_hora_desde']),
      scheduleTo: hhmm(j['plan_hora_hasta']),
      lotNames: ((j['lotes'] as List?) ?? const []).map((e) => 'Lote $e').toList(),
      observations: j['plan_observaciones'] as String?,
      doc: j['documento'] == null
          ? null
          : PlanningDoc(id: '${j['plan_id']}-doc', fileName: j['documento'] as String, sizeBytes: 0),
      status: PlanningStatus.values.firstWhere((x) => x.name == j['plan_estado'],
          orElse: () => PlanningStatus.pendiente),
      rejectionReason: j['plan_observacion_respuesta'] as String?,
      respondedAt: j['plan_respondida_en'] == null ? null : DateTime.parse(j['plan_respondida_en'] as String),
      createdAt: DateTime.parse(j['plan_creada_en'] as String),
      createdByName: j['creador'] as String? ?? '',
      originId: j['plan_id_origen']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'target': target.name,
        'recipient_id': recipientId,
        'recipient_name': recipientName,
        'activity': activity,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'schedule_from': scheduleFrom,
        'schedule_to': scheduleTo,
        'lot_names': lotNames,
        'observations': observations,
        'doc': doc?.toJson(),
        'status': status.name,
        'rejection_reason': rejectionReason,
        'responded_at': respondedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'created_by_name': createdByName,
        'origin_id': originId,
        'lot_results': lotResults.map((k, v) => MapEntry(k, v.dbValue)),
        'lot_justifications': lotJustifications,
      };
}

/// Persona que puede recibir una planificación (técnico o productor).
/// Lo usan los selectores del asistente del Agrónomo.
class Recipient {
  const Recipient({required this.id, required this.name, required this.target});
  final String id;
  final String name;
  final PlanningTarget target;

  factory Recipient.fromJson(Map<String, dynamic> j) => Recipient(
        id: j['id'].toString(),
        name: j['name'] as String,
        target: PlanningTarget.values.firstWhere((t) => t.name == j['target'],
            orElse: () => PlanningTarget.tecnico),
      );
}
