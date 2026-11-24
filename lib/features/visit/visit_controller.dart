import 'package:flutter/foundation.dart';

import '../../core/utils/canonical_json.dart';
import '../../data/app_services.dart';
import '../../data/local/record_owner.dart';
import '../../data/models/lot.dart';
import '../../data/models/reading.dart';
import '../../data/models/trap.dart';
import '../../data/models/visit.dart';

class VisitController extends ChangeNotifier {
  VisitController._();
  static final instance = VisitController._();

  List<Lot> assignedLots = [];
  bool loadingLots = false;
  String? lotsError;

  String? visitId;
  DateTime? visitStartedAt;
  bool get visitInProgress => visitId != null;

  final Map<String, String> _visiIdPorLote = {};

  final Map<String, DateTime> _inicioPorLote = {};

  Lot? activeLot;
  List<Trap> activeTraps = [];
  final Map<String, TrapVisitState> trapStates = {};
  final Map<String, String> skipReasons = {};

  Trap? focusedTrap;

  final Map<String, Map<String, TrapVisitState>> _visitProgress = {};
  final Map<String, Map<String, String>> _visitSkipReasons = {};

  int get readingsThisVisit => _visitProgress.values
      .expand((m) => m.values)
      .where((s) => s == TrapVisitState.registrada)
      .length;

  int get registeredCount =>
      trapStates.values.where((s) => s == TrapVisitState.registrada).length;
  int get handledCount =>
      trapStates.values.where((s) => s != TrapVisitState.pendiente).length;
  int get pendingCount => activeTraps.length - handledCount;
  bool get canFinishLot =>
      activeLot != null && activeTraps.isNotEmpty && pendingCount == 0;

  int get lotsTotal => assignedLots.length;
  int get lotsDone =>
      assignedLots.where((l) => l.status == LotStatus.visitado).length;
  bool get canFinishVisit => lotsTotal > 0 && lotsDone == lotsTotal;

  TrapVisitState stateOf(Trap t) =>
      trapStates[t.id] ?? TrapVisitState.pendiente;

  Trap? get nextTrap {
    for (final t in activeTraps) {
      if (stateOf(t) == TrapVisitState.pendiente) return t;
    }
    return null;
  }

  bool isLocked(Trap t) =>
      stateOf(t) == TrapVisitState.pendiente && nextTrap?.id != t.id;

  Future<void> loadLots() async {
    loadingLots = true;
    lotsError = null;
    notifyListeners();
    try {
      assignedLots = await AppServices.lots
          .getAssignedLots(AppServices.session.value?.userId ?? '');
    } catch (e) {
      lotsError = e.toString();
    } finally {
      loadingLots = false;
      notifyListeners();
    }
  }

  Future<void> startLot(Lot lot) async {
    if (visitId == null) {
      visitId = CanonicalJson.generarUuidV4();
      visitStartedAt = DateTime.now();
      _visitProgress.clear();
      _visitSkipReasons.clear();
      _visiIdPorLote.clear();
      _inicioPorLote.clear();
    }
    activeLot = lot;
    activeTraps = await AppServices.lots.getTraps(lot.id);
    trapStates
      ..clear()
      ..addEntries(
          activeTraps.map((t) => MapEntry(t.id, TrapVisitState.pendiente)));
    skipReasons.clear();

    trapStates.addAll(_visitProgress[lot.id] ?? const {});
    skipReasons.addAll(_visitSkipReasons[lot.id] ?? const {});

    await _registrarVisita(lot);

    if (lot.status == LotStatus.pendiente) {
      await AppServices.lots.updateLotStatus(lot.id, LotStatus.enCurso);
    }
    await _saveVisitRecord(VisitStatus.enProgreso);
    await loadLots();
  }

  String? visiIdParaLote(String lotId) {
    final sesion = visitId;
    if (sesion == null) return null;
    return _visiIdPorLote.putIfAbsent(lotId,
        () => CanonicalJson.uuidDesdeSemilla('visita:$sesion:lote:$lotId'));
  }

  Lot? _loteDe(String lotId) {
    for (final lote in assignedLots) {
      if (lote.id == lotId) return lote;
    }
    return activeLot?.id == lotId ? activeLot : null;
  }

  Future<void> _registrarVisita(Lot lot, {DateTime? porDefecto}) async {
    final visiId = visiIdParaLote(lot.id);
    if (visiId == null) return;
    final inicio =
        _inicioPorLote.putIfAbsent(lot.id, () => porDefecto ?? DateTime.now());
    await AppServices.readings.saveFieldVisit(
      visiId: visiId,
      predioId: lot.predioId,
      lotId: lot.id,
      startedAt: inicio,
      label:
          lot.predioName.isEmpty ? lot.name : '${lot.predioName} · ${lot.name}',
    );
  }

  Future<void> saveReading(Reading reading) async {
    final lote = _loteDe(reading.lotId);
    if (lote != null) {
      await _registrarVisita(lote, porDefecto: reading.observedAt);
    }
    final visiId = visiIdParaLote(reading.lotId);
    final aGuardar = reading.visitId == null && visiId != null
        ? reading.copyWith(visitId: visiId)
        : reading;
    await AppServices.readings.saveReading(aGuardar);
    trapStates[reading.trapId] = TrapVisitState.registrada;
    skipReasons.remove(reading.trapId);
    _visitProgress.putIfAbsent(reading.lotId, () => {})[reading.trapId] =
        TrapVisitState.registrada;
    _visitSkipReasons[reading.lotId]?.remove(reading.trapId);
    notifyListeners();
  }

  Future<void> justifyTrap(Trap trap, String reason) async {
    final lote = _loteDe(trap.lotId);
    if (lote != null) {
      await _registrarVisita(lote);
    }
    await AppServices.readings.justifyTrap(
        trapId: trap.id,
        lotId: trap.lotId,
        reason: reason,
        visitId: visiIdParaLote(trap.lotId));
    trapStates[trap.id] = TrapVisitState.justificada;
    skipReasons[trap.id] = reason;
    _visitProgress.putIfAbsent(trap.lotId, () => {})[trap.id] =
        TrapVisitState.justificada;
    _visitSkipReasons.putIfAbsent(trap.lotId, () => {})[trap.id] = reason;
    notifyListeners();
  }

  Future<bool> finishLot() async {
    final lot = activeLot;
    if (lot == null || !canFinishLot) return false;
    await AppServices.lots.updateLotStatus(lot.id, LotStatus.visitado);
    await AppServices.plannings
        .markLotExecutedForUser(RecordOwner.requerido(), lot.name);
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
    _visiIdPorLote.clear();
    _inicioPorLote.clear();
    notifyListeners();
  }

  void focusTrap(Trap? trap) {
    focusedTrap = trap;
    notifyListeners();
  }

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
    _visiIdPorLote.clear();
    _inicioPorLote.clear();
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
