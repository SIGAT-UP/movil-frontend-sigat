/// Estado del lote dentro de la jornada del técnico.
enum LotStatus {
  pendiente('Pendiente'),
  enCurso('En curso'),
  visitado('Visitado');

  const LotStatus(this.label);
  final String label;

  static LotStatus fromString(String v) =>
      LotStatus.values.firstWhere((s) => s.name == v, orElse: () => LotStatus.pendiente);
}

/// Lote asignado al técnico. Incluye lo necesario para lista y detalle.
class Lot {
  const Lot({
    required this.id,
    required this.code,
    required this.name,
    required this.producer,
    required this.municipality,
    required this.predioId,
    required this.predioName,
    required this.status,
    required this.owner,
    required this.crop,
    required this.areaHa,
    required this.vigilanceActive,
    required this.trapCount,
    this.lastInspection,
    this.lastVisit,
    this.control,
    this.program,
  });

  final String id;
  final String code; // LOTE-A  (BD: lote.lote_codigo = 'A')
  final String name; // Lote A
  final String producer;
  final String municipality; // Pamplona (BD: municipio)
  final String predioId;
  final String predioName; // Finca El Mirador
  final LotStatus status;
  final String owner;
  final String crop;
  final double areaHa;
  final bool vigilanceActive;
  final int trapCount;
  final DateTime? lastInspection;
  final DateTime? lastVisit;
  final LotControl? control;
  final InspectionProgram? program;

  Lot copyWith({LotStatus? status, DateTime? lastVisit}) => Lot(
        id: id,
        code: code,
        name: name,
        producer: producer,
        municipality: municipality,
        predioId: predioId,
        predioName: predioName,
        status: status ?? this.status,
        owner: owner,
        crop: crop,
        areaHa: areaHa,
        vigilanceActive: vigilanceActive,
        trapCount: trapCount,
        lastInspection: lastInspection,
        lastVisit: lastVisit ?? this.lastVisit,
        control: control,
        program: program,
      );

  factory Lot.fromJson(Map<String, dynamic> j) => Lot(
        id: j['id'].toString(),
        code: j['code'] as String,
        name: j['name'] as String,
        producer: j['producer'] as String,
        municipality: j['municipality'] as String,
        predioId: j['predio_id'].toString(),
        predioName: j['predio_name'] as String,
        status: LotStatus.fromString(j['status'] as String),
        owner: j['owner'] as String,
        crop: j['crop'] as String,
        areaHa: (j['area_ha'] as num).toDouble(),
        vigilanceActive: j['vigilance_active'] as bool,
        trapCount: j['trap_count'] as int,
        lastInspection: _date(j['last_inspection']),
        lastVisit: _date(j['last_visit']),
        control: j['control'] == null ? null : LotControl.fromJson(j['control'] as Map<String, dynamic>),
        program: j['program'] == null ? null : InspectionProgram.fromJson(j['program'] as Map<String, dynamic>),
      );
}

/// Construye un Lot desde una fila de `v_lote_app` (lo que devuelve `GET /lots`).
///
/// Reglas de la BD que esto respeta:
///  * El dueño y el productor SALEN DEL PREDIO: son la misma persona (`productor`).
///  * El estado del lote en la jornada (pendiente / en curso / visitado) NO se guarda:
///    se deriva de las visitas. El llamador lo calcula y lo pasa en [status].
///  * `control` y `program` llegan de `GET /lots/:id/control` y `GET /program`.
Lot lotFromApi(Map<String, dynamic> j, {LotStatus status = LotStatus.pendiente}) {
  final cod = j['lote_codigo'].toString();
  final productor = j['productor'] as String? ?? '';
  return Lot(
    id: j['lote_id'].toString(),
    code: 'LOTE-$cod',
    name: j['lote_descripcion'] as String? ?? 'Lote $cod',
    producer: productor,
    owner: productor,
    municipality: j['municipio'] as String? ?? '',
    predioId: j['pred_id'].toString(),
    predioName: j['pred_nombre'] as String? ?? '',
    status: status,
    crop: j['cultivo'] as String? ?? '',
    areaHa: (j['lote_area'] as num?)?.toDouble() ?? 0,
    vigilanceActive: j['vigilancia_activa'] as bool? ?? false,
    trapCount: (j['trampas_vigentes'] as num?)?.toInt() ?? 0,
  );
}

/// Bloque "Control vigente" del detalle del lote.
class LotControl {
  const LotControl({required this.mtd, required this.exportThreshold, required this.aptitude, this.note});
  final double mtd; // moscas / trampa / día
  final String exportThreshold;
  final String aptitude;
  final String? note;

  factory LotControl.fromJson(Map<String, dynamic> j) => LotControl(
        mtd: (j['mtd'] as num).toDouble(),
        exportThreshold: j['export_threshold'] as String,
        aptitude: j['aptitude'] as String,
        note: j['note'] as String?,
      );
}

/// Bloque "Programa de inspección vigente".
class InspectionProgram {
  const InspectionProgram({required this.readingPeriod, required this.goodPractices, required this.scenario});
  final String readingPeriod; // 7–14 días
  final String goodPractices; // Checklist vigente
  final String scenario; // Supresión

  factory InspectionProgram.fromJson(Map<String, dynamic> j) => InspectionProgram(
        readingPeriod: j['reading_period'] as String,
        goodPractices: j['good_practices'] as String,
        scenario: j['scenario'] as String,
      );
}

DateTime? _date(dynamic v) => v == null ? null : DateTime.parse(v as String);
