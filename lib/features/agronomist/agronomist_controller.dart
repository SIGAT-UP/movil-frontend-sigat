import 'package:flutter/foundation.dart';

import '../../core/utils/app_log.dart';
import '../../data/app_services.dart';
import '../../data/models/field_record.dart';
import '../../data/models/lot.dart';
import '../../data/models/lot_summary.dart';
import '../../data/models/planning.dart';
import '../../data/models/producer.dart';
import '../../data/models/trap.dart';
import '../../data/repositories/field_repositories.dart';

/// Estado de las pantallas del Agrónomo.
///
/// Reúne lo que necesita el inicio (estado del lote y registros pendientes),
/// la revisión de registros y la planeación. Todo sale de los repositorios:
/// aquí no se calcula ningún indicador fitosanitario.
class AgronomistController extends ChangeNotifier {
  AgronomistController._();
  static final instance = AgronomistController._();

  /// Lote que se está consultando: el primero de los lotes visibles para el agrónomo
  /// (`GET /lotes`) o el que elija. Ya no hay un lote fijo en el código.
  String? lotId;
  List<Lot> lots = [];

  Lot? lot;
  LotSummary? summary;
  InspectionConfig? config;
  List<ActivityRecord> history = [];
  List<FieldRecord> pendingRecords = [];
  List<Trap> traps = [];
  List<Planning> createdPlannings = [];

  bool loading = false;
  bool busy = false;
  String? error;

  /// Error de la última carga (para mostrar sin conexión / aún no disponible).
  Object? loadError;
  Object? historyError;
  Object? configError;

  static String _mensaje(Object e, String otro) => e is DataException ? e.message : otro;

  /// Lotes del agrónomo; elige el primero si todavía no hay uno seleccionado.
  Future<String> ensureLot() async {
    if (lotId != null) return lotId!;
    lots = await AppServices.lots.getAssignedLots(AppServices.session.value?.userId ?? '');
    if (lots.isEmpty) {
      throw const DataException('No tienes lotes para supervisar. Pide al administrador que te asigne un predio.');
    }
    return lotId = lots.first.id;
  }

  /// Cambia el lote consultado y recarga.
  Future<void> selectLot(String id) async {
    lotId = id;
    summary = null;
    config = null;
    history = [];
    await load();
  }

  int get pendingCount => pendingRecords.length;

  /// Planificaciones creadas, agrupadas por estado para "Mis planificaciones".
  List<Planning> planningsBy(PlanningStatus? status) =>
      status == null ? createdPlannings : createdPlannings.where((p) => p.status == status).toList();

  Planning? planningById(String id) {
    for (final p in createdPlannings) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<void> load() async {
    loading = true;
    error = null;
    loadError = null;
    notifyListeners();
    try {
      final id = await ensureLot();
      final resultados = await Future.wait([
        AppServices.lots.getLot(id),
        AppServices.agronomist.getLotSummary(id),
        AppServices.agronomist.getPendingRecords(),
        AppServices.lots.getTraps(id),
      ]);
      lot = resultados[0] as Lot;
      summary = resultados[1] as LotSummary;
      pendingRecords = resultados[2] as List<FieldRecord>;
      traps = resultados[3] as List<Trap>;
    } catch (e) {
      loadError = e;
      error = _mensaje(e, 'No se pudo cargar la información del lote.');
      AppLog.error('Agronomist.load', e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadHistory() async {
    historyError = null;
    try {
      history = await AppServices.agronomist.getLotHistory(await ensureLot());
    } catch (e) {
      historyError = e;
      AppLog.error('Agronomist.loadHistory', e);
    }
    notifyListeners();
  }

  Future<void> loadConfig() async {
    configError = null;
    try {
      config = await AppServices.agronomist.getInspectionConfig(await ensureLot());
    } catch (e) {
      configError = e;
      AppLog.error('Agronomist.loadConfig', e);
    }
    notifyListeners();
  }

  /// Carga de "Mis planificaciones" (independiente de la carga del inicio).
  bool loadingPlannings = false;
  String? planningsError;

  Future<void> loadCreatedPlannings() async {
    loadingPlannings = true;
    planningsError = null;
    notifyListeners();
    try {
      createdPlannings = await AppServices.plannings.getCreated();
    } catch (e) {
      planningsError = _mensaje(e, 'No se pudieron cargar tus planificaciones.');
      AppLog.error('Agronomist.loadCreatedPlannings', e);
    } finally {
      loadingPlannings = false;
      notifyListeners();
    }
  }

  /// Acepta un registro de campo revisado.
  Future<bool> acceptRecord(String recordId) async {
    if (busy) return false; // evita el doble toque
    busy = true;
    error = null;
    notifyListeners();
    try {
      await AppServices.agronomist.acceptRecord(recordId);
      pendingRecords = await AppServices.agronomist.getPendingRecords();
      return true;
    } catch (e) {
      error = _mensaje(e, 'No se pudo aceptar el registro.');
      AppLog.error('Agronomist.acceptRecord', e);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  FieldRecord? recordById(String id) {
    for (final r in pendingRecords) {
      if (r.id == id) return r;
    }
    return null;
  }

  /// Guarda una planificación nueva (asignación a técnico o planeación a productor).
  Future<bool> createPlanning(Planning planning) async {
    if (busy) return false;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await AppServices.plannings.create(planning);
      createdPlannings = await AppServices.plannings.getCreated();
      return true;
    } catch (e) {
      error = _mensaje(e, 'No se pudo guardar la planificación.');
      AppLog.error('Agronomist.createPlanning', e);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  /// Lecturas registradas de una trampa, para consultarlas en la revisión.
  Future<List<Trap>> trapsOfLot(String id) => AppServices.lots.getTraps(id);

  void reset() {
    lotId = null;
    lots = [];
    loadError = null;
    historyError = null;
    configError = null;
    lot = null;
    summary = null;
    config = null;
    history = [];
    pendingRecords = [];
    traps = [];
    createdPlannings = [];
    loadingPlannings = false;
    planningsError = null;
    loading = false;
    busy = false;
    error = null;
    notifyListeners();
  }
}
