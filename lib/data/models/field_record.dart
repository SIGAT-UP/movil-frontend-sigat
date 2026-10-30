/// Estado de un registro de campo frente a la revisión del Agrónomo.
enum RecordReviewStatus {
  pendiente('Pendiente por aceptar'),
  enRevision('En revisión'),
  aceptado('Aceptado');

  const RecordReviewStatus(this.label);
  final String label;
}

/// Visita de un técnico que llega al Agrónomo para su revisión.
///
/// `reviewReason` explica por qué el sistema la marcó para revisar
/// (por ejemplo, una lectura que se solapa con otra del mismo periodo).
/// Esa regla la aplica el BACKEND: aquí solo se muestra lo que llega.
class FieldRecord {
  const FieldRecord({
    required this.id,
    required this.technicianName,
    required this.observedAt,
    required this.receivedAt,
    required this.lotsVisited,
    required this.trapsTotal,
    required this.lotIds,
    this.reviewReason,
    this.status = RecordReviewStatus.pendiente,
  });

  final String id;
  final String technicianName;

  /// Cuándo se tomó la observación en campo.
  final DateTime observedAt;

  /// Cuándo la recibió el servidor.
  final DateTime receivedAt;

  final int lotsVisited;
  final int trapsTotal;

  /// Lotes incluidos en la visita, para poder consultarlos.
  final List<String> lotIds;

  final String? reviewReason;
  final RecordReviewStatus status;

  FieldRecord copyWith({RecordReviewStatus? status}) => FieldRecord(
        id: id,
        technicianName: technicianName,
        observedAt: observedAt,
        receivedAt: receivedAt,
        lotsVisited: lotsVisited,
        trapsTotal: trapsTotal,
        lotIds: lotIds,
        reviewReason: reviewReason,
        status: status ?? this.status,
      );

  factory FieldRecord.fromJson(Map<String, dynamic> j) => FieldRecord(
        id: j['id'].toString(),
        technicianName: j['technician_name'] as String,
        observedAt: DateTime.parse(j['observed_at'] as String),
        receivedAt: DateTime.parse(j['received_at'] as String),
        lotsVisited: j['lots_visited'] as int,
        trapsTotal: j['traps_total'] as int,
        lotIds: (j['lot_ids'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        reviewReason: j['review_reason'] as String?,
        status: RecordReviewStatus.values.firstWhere((s) => s.name == j['status'],
            orElse: () => RecordReviewStatus.pendiente),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'technician_name': technicianName,
        'observed_at': observedAt.toIso8601String(),
        'received_at': receivedAt.toIso8601String(),
        'lots_visited': lotsVisited,
        'traps_total': trapsTotal,
        'lot_ids': lotIds,
        'review_reason': reviewReason,
        'status': status.name,
      };
}
