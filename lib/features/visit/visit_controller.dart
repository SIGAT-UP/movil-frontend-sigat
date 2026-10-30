import 'package:flutter/foundation.dart';

import '../../data/app_services.dart';
import '../../data/local/record_owner.dart';
import '../../data/models/lot.dart';
import '../../data/models/reading.dart';
import '../../data/models/trap.dart';
import '../../data/models/visit.dart';

/// Estado y reglas de la visita de campo (compartido por todas las pantallas).
///
/// Reglas del negocio:
///  * Un lote se puede finalizar cuando TODAS sus trampas están registradas
///    o justificadas con una observación (motivo por el que no se pudo).
///  * La visita se puede finalizar cuando TODOS los lotes asignados están finalizados.
class VisitController extends ChangeNotifier {
  VisitController._();
  static final instance = VisitController._();

  // ---------- Lotes asignados ----------
  List<Lot> assignedLots = [];
  bool loadingLots = false;
  String? lotsError;

  // ---------- Visita ----------
  String? visitId;
  DateTime? visitStartedAt;
  bool get visitInProgress => visitId != null;

  // ---------- Lote activo ----------
  Lot? activeLot;
  List<Trap> activeTraps = [];
  final Map<String, TrapVisitState> trapStates = {};
  final Map<String, String> skipReasons = {};

  /// Trampa a resaltar cuando se abre el mapa ("Ver en el mapa").
  Trap? focusedTrap;

  /// Avance de la visita EN CURSO, por lote: trapId → estado (y motivo si se
  /// justificó). Solo cuenta lo registrado o justificado en esta visita.
  /// Las lecturas de visitas anteriores (las que revisa el agrónomo) NO marcan
  /// trampas como hechas: cada visita empieza con todas las trampas pendientes.
  final Map<String, Map<String, TrapVisitState>> _visitProgress = {};
  final Map<String, Map<String, String>> _visitSkipReasons = {};

  /// Lecturas registradas en la visita en curso (resumen de "Finalizar visita").
  int get readingsThisVisit => _visitProgress.values
      .expand((m) => m.values)
      .where((s) => s == TrapVisitState.registrada)
      .length;

  // ---------- Derivados ----------
  int get registeredCount => trapStates.values.where((s) => s == TrapVisitState.registrada).length;
  int get handledCount => trapStates.values.where((s) => s != TrapVisitState.pendiente).length;
  int get pendingCount => activeTraps.length - handledCount;
  bool get canFinishLot => activeLot != null && activeTraps.isNotEmpty && pendingCount == 0;

  int get lotsTotal => assignedLots.length;
  int get lotsDone => assignedLots.where((l) => l.status == LotStatus.visitado).length;
  bool get canFinishVisit => lotsTotal > 0 && lotsDone == lotsTotal;

  TrapVisitState stateOf(Trap t) => trapStates[t.id] ?? TrapVisitState.pendiente;

  /// Recorrido en orden: la siguiente trampa a visitar es la primera pendiente.
  Trap? get nextTrap {
    for (final t in activeTraps) {
      if (stateOf(t) == TrapVisitState.pendiente) return t;
    }
    return null;
  }

  /// Una trampa pendiente que NO es la siguiente queda bloqueada.
  bool isLocked(Trap t) => stateOf(t) == TrapVisitState.pendiente && nextTrap?.id != t.id;

  // ---------- Acciones ----------
  Future<void> loadLots() async {
    loadingLots = true;
    lotsError = null;
    notifyListeners();
    try {
      assignedLots = await AppServices.lots.getAssignedLots(AppServices.session.value?.userId ?? '');
    } catch (e) {
      lotsError = e.toString();
    } finally {
      loadingLots = false;
      notifyListeners();
    }
  }

  /// "Iniciar inspección" desde el detalle del lote.
  Future<void> startLot(Lot lot) async {
    if (visitId == null) {
      visitId = 'v-${DateTime.now().millisecondsSinceEpoch}';
      visitStartedAt = DateTime.now();
      _visitProgress.clear();
      _visitSkipReasons.clear();
    }
    activeLot = lot;
    activeTraps = await AppServices.lots.getTraps(lot.id);
    trapStates
      ..clear()
      ..addEntries(activeTraps.map((t) => MapEntry(t.id, TrapVisitState.pendiente)));
    skipReasons.clear();

    // Si este lote ya se trabajó en ESTA visita (se salió y volvió), se respeta
    // lo hecho. Lecturas de visitas anteriores no cuentan.
    trapStates.addAll(_visitProgress[lot.id] ?? const {});
    skipReasons.addAll(_visitSkipReasons[lot.id] ?? const {});

    if (lot.status == LotStatus.pendiente) {
      await AppServices.lots.updateLotStatus(lot.id, LotStatus.enCurso);
    }
    await _saveVisitRecord(VisitStatus.enProgreso);
    await loadLots();
  }

  Future<void> saveReading(Reading reading) async {
    await AppServices.readings.saveReading(reading);
    trapStates[reading.trapId] = TrapVisitState.registrada;
    skipReasons.remove(reading.trapId);
    _visitProgress.putIfAbsent(reading.lotId, () => {})[reading.trapId] = TrapVisitState.registrada;
    _visitSkipReasons[reading.lotId]?.remove(reading.trapId);
    notifyListeners();
  }

  /// Trampa que no se pudo registrar: queda justificada con el motivo.
  Future<void> justifyTrap(Trap trap, String reason) async {
    await AppServices.readings.justifyTrap(trapId: trap.id, lotId: trap.lotId, reason: reason);
    trapStates[trap.id] = TrapVisitState.justificada;
    skipReasons[trap.id] = reason;
    _visitProgress.putIfAbsent(trap.lotId, () => {})[trap.id] = TrapVisitState.justificada;
    _visitSkipReasons.putIfAbsent(trap.lotId, () => {})[trap.id] = reason;
    notifyListeners();
  }

  /// Finaliza el lote activo. Devuelve true si ya se terminaron todos los lotes.
  Future<bool> finishLot() async {
    final lot = activeLot;
    if (lot == null || !canFinishLot) return false;
    await AppServices.lots.updateLotStatus(lot.id, LotStatus.visitado);
    // BD: terminar el lote cumple su parte en las actividades asignadas al técnico
    // (`planificacion_lote` → ejecutada). Si era el último, la actividad se completa sola.
    // Sin sesión válida lanza SinSesionException: nunca se guarda un resultado sin dueño.
    await AppServices.plannings.markLotExecutedForUser(RecordOwner.requerido(), lot.name);
    activeLot = null;
    activeTraps = [];
    trapStates.clear();
    skipReasons.clear();
    focusedTrap = null;
    await loadLots();
    await _saveVisitRecord(VisitStatus.enProgreso);
    return canFinishVisit;
  }

  Future<void> finishVisit() async {
    if (!canFinishVisit) return;
    await _saveVisitRecord(VisitStatus.completada);
    visitId = null;
    visitStartedAt = null;
    _visitProgress.clear();
    _visitSkipReasons.clear();
    notifyListeners();
  }

  void focusTrap(Trap? trap) {
    focusedTrap = trap;
    notifyListeners();
  }

  /// Al cerrar sesión.
  void reset() {
    assignedLots = [];
    visitId = null;
    visitStartedAt = null;
    activeLot = null;
    activeTraps = [];
    trapStates.clear();
    skipReasons.clear();
    focusedTrap = null;
    _visitProgress.clear();
    _visitSkipReasons.clear();
    notifyListeners();
  }

  Future<void> _saveVisitRecord(VisitStatus status) async {
    final id = visitId;
    if (id == null) return;
    await AppServices.history.saveVisit(VisitRecord(
      id: id,
      date: visitStartedAt ?? DateTime.now(),
      lotsDone: lotsDone,
      lotsTotal: lotsTotal,
      status: status,
    ));
  }
}
