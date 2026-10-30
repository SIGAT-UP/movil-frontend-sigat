/// Resumen del cultivo del productor (P01 Inicio / P02 Estado de mi cultivo).
class CropSummary {
  const CropSummary({
    required this.crop,
    required this.lotLabel,
    required this.vigilanceActive,
    required this.cropStatus,
    required this.lotsReviewed,
    this.lastVisit,
    this.lastMtd,
    this.lastApplication,
  });

  final String crop; // Durazno
  final String lotLabel; // Lote de producción
  final bool vigilanceActive;
  final String cropStatus; // Activa
  final int lotsReviewed;
  final DateTime? lastVisit;

  /// Último MTD con cálculo válido (lo emite el servidor). null = no existe.
  final double? lastMtd;
  final DateTime? lastApplication;

  factory CropSummary.fromJson(Map<String, dynamic> j) => CropSummary(
        crop: j['crop'] as String,
        lotLabel: j['lot_label'] as String,
        vigilanceActive: j['vigilance_active'] as bool,
        cropStatus: j['crop_status'] as String,
        lotsReviewed: j['lots_reviewed'] as int,
        lastVisit: _d(j['last_visit']),
        lastMtd: (j['last_mtd'] as num?)?.toDouble(),
        lastApplication: _d(j['last_application']),
      );
}

/// Autorreporte: aplicación fitosanitaria (P03).
class PhytoApplication {
  const PhytoApplication({
    required this.id,
    required this.date,
    required this.product,
    required this.doseMlPerLiter,
    required this.areaHa,
    required this.responsible,
  });

  final String id;
  final DateTime date;
  final String product;
  final double doseMlPerLiter;
  final double areaHa;
  final String responsible;

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'product': product,
        'dose_ml_per_liter': doseMlPerLiter,
        'area_ha': areaHa,
        'responsible': responsible,
      };

  factory PhytoApplication.fromJson(Map<String, dynamic> j) => PhytoApplication(
        id: j['id'] as String,
        date: DateTime.parse(j['date'] as String),
        product: j['product'] as String,
        doseMlPerLiter: (j['dose_ml_per_liter'] as num).toDouble(),
        areaHa: (j['area_ha'] as num).toDouble(),
        responsible: j['responsible'] as String,
      );
}

/// Autorreporte: cosecha (P04).
class HarvestReport {
  const HarvestReport({required this.id, required this.expectedDate, required this.volumeKg, this.actualDate});

  final String id;
  final DateTime expectedDate;
  final DateTime? actualDate; // null = pendiente
  final double volumeKg;

  Map<String, dynamic> toJson() => {
        'id': id,
        'expected_date': expectedDate.toIso8601String(),
        'actual_date': actualDate?.toIso8601String(),
        'volume_kg': volumeKg,
      };

  factory HarvestReport.fromJson(Map<String, dynamic> j) => HarvestReport(
        id: j['id'] as String,
        expectedDate: DateTime.parse(j['expected_date'] as String),
        actualDate: j['actual_date'] == null ? null : DateTime.parse(j['actual_date'] as String),
        volumeKg: (j['volume_kg'] as num).toDouble(),
      );
}

enum ActivityType {
  vigilancia('Vigilancia'),
  aplicacion('Aplicación'),
  cosecha('Cosecha');

  const ActivityType(this.label);
  final String label;
}

/// Evento del historial del productor (visitas del técnico + sus autorreportes).
class ActivityRecord {
  const ActivityRecord({required this.id, required this.type, required this.date, required this.title, this.subtitle});

  final String id;
  final ActivityType type;
  final DateTime date;
  final String title;
  final String? subtitle;

  factory ActivityRecord.fromJson(Map<String, dynamic> j) => ActivityRecord(
        id: j['id'].toString(),
        type: ActivityType.values.firstWhere((t) => t.name == j['type'], orElse: () => ActivityType.vigilancia),
        date: DateTime.parse(j['date'] as String),
        title: j['title'] as String,
        subtitle: j['subtitle'] as String?,
      );
}

DateTime? _d(dynamic v) => v == null ? null : DateTime.parse(v as String);
