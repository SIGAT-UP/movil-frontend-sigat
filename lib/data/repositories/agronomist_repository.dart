import '../models/field_record.dart';
import '../models/lot_summary.dart';
import '../models/producer.dart';
import '../models/reading.dart';
import '../models/trap.dart';

/// Contrato de las consultas del Agrónomo.
///
/// Operaciones que deberá ofrecer el backend:
///   GET   /agronomist/records?status=pending -> getPendingRecords
///   GET   /agronomist/records/{id}           -> getRecord
///   PATCH /agronomist/records/{id}/accept    -> acceptRecord
///   GET   /lots/{id}/summary                 -> getLotSummary
///   GET   /lots/{id}/history                 -> getLotHistory
///   GET   /lots/{id}/config                  -> getInspectionConfig
///
/// El MTD, el escenario y el umbral los CALCULA el servidor. La app no los
/// deduce: solo los presenta.
abstract class AgronomistRepository {
  /// Registros de campo pendientes de revisión.
  Future<List<FieldRecord>> getPendingRecords();

  Future<FieldRecord> getRecord(String recordId);

  /// Acepta el registro revisado.
  Future<FieldRecord> acceptRecord(String recordId);

  /// Resumen fitosanitario del lote.
  Future<LotSummary> getLotSummary(String lotId);

  /// Historial del lote (inspecciones, aplicaciones, correcciones).
  Future<List<ActivityRecord>> getLotHistory(String lotId);

  /// Programa de inspección y escenarios de trampeo vigentes.
  Future<InspectionConfig> getInspectionConfig(String lotId);

  /// Trampa y su última lectura RECIBIDA por el servidor (null = aún sin lecturas).
  Future<(Trap, Reading?)> trapWithLastReading(String trapId);
}
