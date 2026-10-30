import '../models/app_notification.dart';

/// Contrato de los avisos dirigidos al usuario autenticado.
///
/// IMPORTANTE: los avisos NO los crea la aplicación. Los genera el backend
/// cuando ocurre un evento real (por ejemplo, cuando alguien autorizado asigna
/// un lote o una inspección a un técnico). Por eso este contrato solo tiene
/// operaciones de consulta y de marcar como leído.
///
/// Operaciones que deberá ofrecer el backend:
///   GET   /me/notifications?unread=                -> getForUser
///   GET   /me/notifications/unread-count           -> unreadCount
///   PATCH /me/notifications/{id}      {read:true}  -> markAsRead
///   PATCH /me/notifications/read-all               -> markAllAsRead
///
/// El servidor debe:
///  * Deducir el destinatario del token, no de un id enviado por la app.
///  * Devolver ÚNICAMENTE los avisos de ese usuario.
///  * Rechazar marcar como leído un aviso de otro usuario.
///  * Evitar duplicados por evento (una asignación = un aviso).
abstract class NotificationsRepository {
  /// Avisos del usuario, del más reciente al más antiguo.
  Future<List<AppNotification>> getForUser(String userId);

  Future<int> unreadCount(String userId);

  Future<void> markAsRead(String userId, String notificationId);

  Future<void> markAllAsRead(String userId);
}
