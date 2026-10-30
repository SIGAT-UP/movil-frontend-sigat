import 'package:flutter/foundation.dart';

import '../../core/utils/app_log.dart';

import '../../data/app_services.dart';
import '../../data/models/photo_file.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/field_repositories.dart';

/// Estado del perfil del usuario autenticado (M13-T).
///
/// Es la ÚNICA fuente de la foto y de la preferencia de notificaciones: el
/// avatar del perfil y el del menú lateral leen de aquí, no guardan copias.
class ProfileController extends ChangeNotifier {
  ProfileController._();
  static final instance = ProfileController._();

  UserProfile? profile;
  bool loading = false;
  bool savingPhoto = false;
  bool savingNotifications = false;

  /// Error de guardado, para mostrar al usuario.
  String? error;

  /// Aviso informativo verdadero (ej. "guardada en el dispositivo").
  String? notice;

  NotificationPreferences get notifications => profile?.notifications ?? const NotificationPreferences();

  String? get _userId => AppServices.session.value?.userId;

  Future<void> load() async {
    final id = _userId;
    if (id == null) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      profile = await AppServices.profile.getProfile(id);
    } catch (e) {
      error = e is DataException ? e.message : 'No se pudo cargar tu perfil.';
      AppLog.error('ProfileController.load', e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Guarda la foto en el dispositivo e INTENTA enviarla al servidor.
  /// Si no hay servidor, la deja pendiente y lo dice con [notice].
  /// Devuelve true si la foto quedó aplicada en el perfil.
  Future<bool> setPhoto(PhotoFile photo) async {
    final id = _userId;
    if (id == null) return false;
    savingPhoto = true;
    error = null;
    notice = null;
    notifyListeners();
    try {
      profile = await AppServices.profile.saveProfilePhotoLocally(id, photo);
      notifyListeners();
    } catch (e) {
      savingPhoto = false;
      error = 'No se pudo guardar la fotografía en el dispositivo.';
      AppLog.error('ProfileController.setPhoto', e);
      notifyListeners();
      return false;
    }

    // Envío al servidor: hoy no existe, así que queda pendiente.
    try {
      final ref = await AppServices.profile.uploadProfilePhoto(id, photo);
      profile = profile?.copyWith(photoRemoteRef: ref, photoStatus: UploadStatus.uploaded);
      notice = 'Fotografía actualizada.';
    } on BackendNotAvailable catch (e) {
      profile = profile?.copyWith(photoStatus: UploadStatus.local);
      notice = e.message;
    } catch (e) {
      profile = profile?.copyWith(photoStatus: UploadStatus.failed);
      notice = 'La foto quedó guardada en el dispositivo. No se pudo enviar al servidor.';
      AppLog.error('ProfileController.upload', e);
    } finally {
      savingPhoto = false;
      notifyListeners();
    }
    return true;
  }

  Future<bool> removePhoto() async {
    final id = _userId;
    if (id == null) return false;
    savingPhoto = true;
    error = null;
    notice = null;
    notifyListeners();
    try {
      profile = await AppServices.profile.removeProfilePhoto(id);
      notice = 'Se quitó la fotografía.';
      return true;
    } catch (e) {
      error = 'No se pudo quitar la fotografía.';
      AppLog.error('ProfileController.removePhoto', e);
      return false;
    } finally {
      savingPhoto = false;
      notifyListeners();
    }
  }

  /// Cambia el interruptor de notificaciones. La interfaz responde de
  /// inmediato y, si el guardado falla, el valor vuelve atrás.
  Future<bool> setNotificationsEnabled(bool value) async {
    final id = _userId;
    if (id == null) return false;
    final previous = notifications;
    profile = (profile ?? UserProfile(userId: id)).copyWith(notifications: previous.copyWith(enabled: value));
    savingNotifications = true;
    error = null;
    notifyListeners();
    try {
      final saved = await AppServices.profile.updateNotifications(id, previous.copyWith(enabled: value));
      profile = profile?.copyWith(notifications: saved);
      return true;
    } catch (e) {
      profile = profile?.copyWith(notifications: previous); // se revierte
      // Se dice el motivo real (p. ej. el servidor aún no guarda preferencias): nunca se finge guardado.
      error = e is BackendNotAvailable ? e.message : 'No se pudo guardar la preferencia. Intenta de nuevo.';
      AppLog.error('ProfileController.setNotificationsEnabled', e);
      return false;
    } finally {
      savingNotifications = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    error = null;
    notice = null;
  }

  /// Al cerrar sesión: el siguiente usuario no debe ver la foto del anterior.
  void reset() {
    profile = null;
    loading = false;
    savingPhoto = false;
    savingNotifications = false;
    error = null;
    notice = null;
    notifyListeners();
  }
}
