import 'package:flutter/foundation.dart';

import '../../core/utils/app_log.dart';
import '../../data/app_services.dart';
import '../../data/models/planning.dart';
import '../../data/repositories/field_repositories.dart';

/// Planificaciones que RECIBE el usuario autenticado (técnico o productor).
///
/// Es la única fuente de verdad de la lista y del detalle: las dos pantallas
/// leen de aquí, así que al aceptar o rechazar el cambio se ve en ambas.
class PlanningInboxController extends ChangeNotifier {
  PlanningInboxController._();
  static final instance = PlanningInboxController._();

  List<Planning> items = [];
  bool loading = false;
  bool responding = false;
  String? error;

  String? get _userId => AppServices.session.value?.userId;

  int get pendingCount => items.where((p) => p.status == PlanningStatus.pendiente).length;

  Planning? byId(String id) {
    for (final p in items) {
      if (p.id == id) return p;
    }
    return null;
  }

  List<Planning> filtered(PlanningStatus? status) =>
      status == null ? items : items.where((p) => p.status == status).toList();

  Future<void> load() async {
    final id = _userId;
    if (id == null) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      items = await AppServices.plannings.getReceived(id);
    } catch (e) {
      error = e is DataException ? e.message : 'No se pudieron cargar tus planificaciones.';
      AppLog.error('PlanningInbox.load', e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> accept(String id) => _respond(() => AppServices.plannings.accept(id));

  Future<bool> reject(String id, String reason) =>
      _respond(() => AppServices.plannings.reject(id, reason));

  Future<bool> _respond(Future<Planning> Function() action) async {
    if (responding) return false; // evita el doble toque
    responding = true;
    error = null;
    notifyListeners();
    try {
      final actualizada = await action();
      final i = items.indexWhere((p) => p.id == actualizada.id);
      if (i >= 0) items[i] = actualizada;
      return true;
    } catch (e) {
      error = 'No se pudo registrar tu respuesta. Intenta de nuevo.';
      AppLog.error('PlanningInbox.respond', e);
      return false;
    } finally {
      responding = false;
      notifyListeners();
    }
  }

  void reset() {
    items = [];
    loading = false;
    responding = false;
    error = null;
    notifyListeners();
  }
}
