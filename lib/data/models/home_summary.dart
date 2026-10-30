/// Resumen de la jornada para la pantalla de inicio del técnico (`GET /yo/inicio`).
///
/// Los conteos son null cuando el servidor todavía no los entrega (bloque `tecnico`
/// pendiente en el backend): la pantalla muestra «—», nunca un número inventado.
class HomeSummary {
  const HomeSummary({
    required this.date,
    this.assignedLots,
    this.pendingVisits,
    this.nextVisitTime,
    this.lastSync,
    this.unreadNotifications = 0,
    this.pendingLocal = 0,
  });

  final DateTime date;
  final int? assignedLots;
  final int? pendingVisits;
  final String? nextVisitTime; // "9:41"
  final DateTime? lastSync;
  final int unreadNotifications;

  /// Registros guardados en este teléfono que el servidor aún no confirmó.
  final int pendingLocal;

  factory HomeSummary.fromJson(Map<String, dynamic> j) => HomeSummary(
        date: DateTime.parse(j['date'] as String),
        assignedLots: j['assigned_lots'] as int?,
        pendingVisits: j['pending_visits'] as int?,
        nextVisitTime: j['next_visit_time'] as String?,
        lastSync: j['last_sync'] == null ? null : DateTime.parse(j['last_sync'] as String),
      );
}
