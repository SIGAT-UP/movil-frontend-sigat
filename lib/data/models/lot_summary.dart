/// Un punto de la curva de MTD (moscas por trampa y día).
class MtdPoint {
  const MtdPoint(this.date, this.value);
  final DateTime date;
  final double value;
}

/// Escenario de trampeo (Tabla 1 de la norma de vigilancia).
/// Los rangos los define la norma: aquí solo se muestran.
class TrappingScenario {
  const TrappingScenario({required this.name, required this.rule, this.isCurrent = false, this.pending = false});
  final String name;
  final String rule;

  /// Escenario vigente según el MTD del último periodo cerrado.
  final bool isCurrent;

  /// Marcado como "por definir" (ej. umbral de exportación sin emitir).
  final bool pending;
}

/// Programa de inspección vigente del lote.
class InspectionConfig {
  const InspectionConfig({
    required this.readingPeriodDays,
    required this.trapsConfigured,
    required this.verification,
    required this.scenarios,
  });

  final int readingPeriodDays;
  final int trapsConfigured;

  /// "Aviso, no bloquea" — cómo actúa el sistema ante una incoherencia.
  final String verification;

  final List<TrappingScenario> scenarios;
}

/// Resumen fitosanitario del lote que consulta el Agrónomo.
///
/// Todos los valores los calcula el BACKEND. La app no deduce escenarios ni
/// umbrales: los muestra tal como llegan.
class LotSummary {
  const LotSummary({
    required this.lotId,
    required this.lotName,
    required this.scenario,
    required this.mtd,
    required this.exportThreshold,
    required this.aptitudeConcept,
    required this.series,
    required this.scenarioLimit,
    required this.inspectionsThisMonth,
    required this.applications,
    required this.lastApplication,
    required this.trapsTotal,
    required this.lastVisit,
    required this.readingsTotal,
    required this.specimensDetected,
    required this.trapsWithFindings,
    required this.phenologicalStage,
    required this.estimatedYieldKg,
    required this.actualYieldKg,
    required this.goodPracticesLabel,
    required this.activeFindings,
    this.pendingReviewLabel,
    this.expectedHarvest,
  });

  final String lotId;
  final String lotName;

  /// "Supresión", "Erradicación", "Área infestada", "Exclusión".
  final String scenario;

  /// MTD del último periodo cerrado. null = sin cálculo válido.
  final double? mtd;
  final String exportThreshold;
  final String aptitudeConcept;

  /// Serie para el gráfico de tendencia.
  final List<MtdPoint> series;

  /// Línea de referencia del escenario en el gráfico.
  final double scenarioLimit;

  final int inspectionsThisMonth;
  final int applications;
  final DateTime? lastApplication;

  final int trapsTotal;
  final DateTime? lastVisit;
  final int readingsTotal;
  final int specimensDetected;
  final int trapsWithFindings;

  /// Etapa fenológica del cultivo (ej. "Fructificación").
  final String phenologicalStage;

  final double? estimatedYieldKg;
  final double? actualYieldKg;

  /// Estado de las Buenas Prácticas Agrícolas.
  final String goodPracticesLabel;

  /// Hallazgos vigentes sin resolver.
  final int activeFindings;

  /// Aviso de registro por revisar, si lo hay.
  final String? pendingReviewLabel;

  final DateTime? expectedHarvest;
}
