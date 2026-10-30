import 'package:flutter/foundation.dart';

import '../../data/app_services.dart';
import '../../data/connectivity_service.dart';
import '../../data/models/visit.dart';
import '../../data/repositories/field_repositories.dart';

enum SyncPhase { idle, syncing, done, error }

/// Sincronización en segundo plano, COMPARTIDA por todos los roles.
/// Cada usuario solo ve y envía sus propios registros (lo filtra el repositorio).
/// Sigue avanzando aunque el usuario cambie de pantalla.
class SyncController extends ChangeNotifier {
  SyncController._();
  static final instance = SyncController._();

  SyncPhase phase = SyncPhase.idle;
  List<SyncItem> items = [];
  int syncedCount = 0;

  /// Índice del registro que se está enviando (para mostrar "Enviando...").
  int? currentIndex;
  DateTime? lastSync;
  String? error;
  bool loading = false;

  int get pendingCount => items.where((i) => !i.synced).length;
  bool get isSyncing => phase == SyncPhase.syncing;

  Future<void> load() async {
    if (isSyncing) return;
    loading = true;
    notifyListeners();
    items = await AppServices.sync.getPending();
    lastSync = await AppServices.sync.lastSync();
    syncedCount = 0;
    currentIndex = null;
    phase = items.isEmpty ? SyncPhase.done : SyncPhase.idle;
    error = null;
    loading = false;
    notifyListeners();
  }

  Future<void> syncAll() async {
    if (isSyncing || items.isEmpty) return;
    // Verifica la conexión real justo antes de enviar.
    final online = await ConnectivityService.instance.refresh();
    if (!online) {
      phase = SyncPhase.error;
      error = 'Sin conexión. Los datos siguen guardados en el dispositivo.';
      notifyListeners();
      return;
    }
    phase = SyncPhase.syncing;
    error = null;
    notifyListeners();
    for (var i = 0; i < items.length; i++) {
      if (items[i].synced) continue;
      currentIndex = i;
      notifyListeners();
      try {
        await AppServices.sync.syncItem(items[i]);
        items[i] = items[i].markSynced();
        syncedCount++;
      } catch (e) {
        currentIndex = null;
        phase = SyncPhase.error;
        // El repositorio dice el motivo real (sin conexión, servidor aún sin sincronización…).
        error = e is DataException
            ? e.message
            : 'Se detuvo la sincronización. Tus datos siguen guardados en este teléfono: puedes reintentar.';
        items = await AppServices.sync.getPending();
        notifyListeners();
        return;
      }
    }
    currentIndex = null;
    lastSync = await AppServices.sync.lastSync();
    phase = SyncPhase.done;
    notifyListeners();
  }

  /// Al cerrar sesión: el siguiente usuario empieza con su propia cola.
  void reset() {
    phase = SyncPhase.idle;
    items = [];
    syncedCount = 0;
    currentIndex = null;
    error = null;
    loading = false;
    notifyListeners();
  }
}
