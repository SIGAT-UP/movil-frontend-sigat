import '../models/photo_file.dart';
import '../models/user_profile.dart';

/// Se lanza cuando una operación necesita el servidor y todavía no existe.
/// La UI la usa para decir la verdad: "guardado en el dispositivo, pendiente
/// de enviar", en vez de dar por hecho que el servidor recibió el dato.
class BackendNotAvailable implements Exception {
  const BackendNotAvailable([this.message = 'Todavía no hay conexión con el servidor.']);
  final String message;
  @override
  String toString() => message;
}

/// Contrato del perfil del usuario autenticado (foto y preferencias).
///
/// Operaciones que deberá ofrecer el backend:
///   GET    /me/profile                   -> getProfile
///   PATCH  /me/notifications             -> updateNotifications
///   POST   /me/photo        (multipart)  -> uploadProfilePhoto
///   DELETE /me/photo                     -> removeProfilePhoto
/// El servidor debe validar de nuevo contenido, tipo y tamaño de la imagen,
/// y autorizar por el token: nunca por un id enviado desde la app.
abstract class ProfileRepository {
  Future<UserProfile> getProfile(String userId);

  /// Guarda la foto en el dispositivo y la deja PENDIENTE de enviar.
  /// No contacta al servidor.
  Future<UserProfile> saveProfilePhotoLocally(String userId, PhotoFile photo);

  /// Quita la foto del perfil (local y, cuando exista, también en el servidor).
  Future<UserProfile> removeProfilePhoto(String userId);

  /// Envía la foto al servidor y devuelve su referencia permanente.
  /// Mientras no exista backend lanza [BackendNotAvailable].
  Future<String> uploadProfilePhoto(String userId, PhotoFile photo);

  /// Guarda la preferencia de notificaciones del usuario.
  Future<NotificationPreferences> updateNotifications(String userId, NotificationPreferences prefs);
}
