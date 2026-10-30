import '../models/planning.dart';

/// Contrato de las planificaciones (asignaciones a técnicos y planeaciones a
/// productores). Un solo contrato para los dos casos.
///
/// Operaciones que deberá ofrecer el backend:
///   GET   /me/plannings                     -> getReceived   (las que recibo)
///   GET   /plannings?created_by=me          -> getCreated    (las que creé)
///   POST  /plannings                        -> create
///   PATCH /plannings/{id}/accept            -> accept
///   PATCH /plannings/{id}/reject {reason}   -> reject
///   GET   /recipients?target=tecnico        -> getRecipients
///
/// El servidor debe deducir el usuario del token, comprobar que solo el
/// destinatario puede responder y que solo un Agrónomo puede crear.
abstract class PlanningRepository {
  /// Planificaciones dirigidas a este usuario (técnico o productor).
  Future<List<Planning>> getReceived(String userId);

  /// Planificaciones creadas por el Agrónomo.
  Future<List<Planning>> getCreated();

  /// Personas a las que se puede dirigir una planificación.
  Future<List<Recipient>> getRecipients(PlanningTarget target);

  /// Lotes disponibles para asignar (nombres).
  Future<List<String>> getAssignableLots();

  Future<Planning> create(Planning planning);

  /// Solo el PRODUCTOR acepta. La actividad de un técnico ya nace autorizada:
  /// el repositorio lanza [StateError] si se intenta aceptarla o rechazarla.
  Future<Planning> accept(String planningId);

  /// `reason` es obligatorio: sin motivo no se puede rechazar.
  Future<Planning> reject(String planningId, String reason);

  /// El TÉCNICO registra el resultado de SU actividad en un lote
  /// (BD `planificacion_lote.plal_estado`). Reglas de la BD:
  ///  * solo el técnico destinatario, solo mientras la actividad está pendiente;
  ///  * un lote se resuelve UNA sola vez;
  ///  * "no ejecutada" exige justificación;
  ///  * cuando todos los lotes tienen resultado, la actividad pasa a completada.
  Future<Planning> reportLotResult(
    String planningId,
    String lotName, {
    required bool executed,
    String? justification,
  });

  /// Marca como ejecutado [lotName] en todas las actividades pendientes del técnico
  /// que lo incluyen. Lo llama la app al terminar la visita de ese lote.
  Future<void> markLotExecutedForUser(String userId, String lotName);
}
