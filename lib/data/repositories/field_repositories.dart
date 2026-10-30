import '../models/lot.dart';
import '../models/reading.dart';
import '../models/trap.dart';
import '../models/visit.dart';

/// Contratos del trabajo de campo. La UI solo conoce estas interfaces; las
/// implementaciones contra el backend están en `api_repositories.dart` y se
/// registran en `lib/data/app_services.dart`.

/// Error controlado con mensaje para mostrar al usuario.
class DataException implements Exception {
  const DataException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// La ruta existe en el contrato del backend pero todavía no está programada (501).
/// La pantalla lo dice tal cual; nunca muestra datos inventados en su lugar.
class NotAvailableYet extends DataException {
  const NotAvailableYet(super.message);
}

/// No hay conexión con el servidor (o no respondió a tiempo).
class OfflineException extends DataException {
  const OfflineException(super.message);
}

abstract class LotsRepository {
  Future<List<Lot>> getAssignedLots(String userId);
  Future<Lot> getLot(String lotId);
  Future<List<Trap>> getTraps(String lotId);
  Future<void> updateLotStatus(String lotId, LotStatus status);
}

abstract class TrapsRepository {
  /// Busca por código ICA (QR o digitado). Devuelve null si no existe en el catálogo.
  Future<TrapLookup?> findByCode(String code, {String? activeLotId});
}

abstract class ReadingsRepository {
  /// Guarda la lectura en local (pendiente de sincronizar).
  Future<void> saveReading(Reading reading);

  /// Marca una trampa como no registrada con su motivo.
  Future<void> justifyTrap({required String trapId, required String lotId, required String reason});

  Future<List<Reading>> readingsForLot(String lotId);
}

abstract class MapRepository {
  /// ¿El mosaico satelital del predio está descargado en el dispositivo?
  Future<bool> isMapDownloaded(String predioId);

  /// Descarga el mapa (requiere conexión). `onProgress` de 0 a 1.
  Future<void> downloadMap(String predioId, {void Function(double progress)? onProgress});
}

abstract class SyncRepository {
  Future<List<SyncItem>> getPending();
  Future<void> syncItem(SyncItem item);
  Future<DateTime?> lastSync();
}

abstract class HistoryRepository {
  Future<List<VisitRecord>> getVisits();
  Future<void> saveVisit(VisitRecord visit);
}
