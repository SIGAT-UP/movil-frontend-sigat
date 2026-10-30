import 'package:flutter/foundation.dart';

import '../../core/utils/app_log.dart';
import '../../core/widgets/app_messenger.dart';
import '../../data/app_services.dart';
import '../../data/models/app_notification.dart';
import '../../data/repositories/field_repositories.dart';
import '../profile/profile_controller.dart';

/// Bandeja de avisos del usuario autenticado.
///
/// La app NO genera avisos: los consulta al repositorio. Lo único que decide
/// aquí es si, además de aparecer en la bandeja, se muestra una alerta dentro
/// de la app cuando llegan avisos nuevos. Esa alerta respeta la preferencia
/// del usuario ("Notificaciones" en el perfil).
///
/// Desactivar la preferencia NO borra ningún aviso: se siguen viendo en la
/// bandeja; lo que se suprime es el aviso emergente.
class NotificationsController extends ChangeNotifier {
  NotificationsController._();
  static final instance = NotificationsController._();

  List<AppNotification> items = [];
  bool loading = false;
  String? error;

  /// Ids ya conocidos, para no avisar dos veces del mismo.
  final Set<String> _known = {};
  bool _firstLoadDone = false;

  int get unreadCount => items.where((n) => !n.read).length;
  bool get hasUnread => unreadCount > 0;

  String? get _userId => AppServices.session.value?.userId;

  Future<void> load() async {
    final id = _userId;
    if (id == null) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final fetched = await AppServices.notifications.getForUser(id);

      // Avisos que no estaban en la consulta anterior.
      final nuevos = fetched.where((n) => !n.read && !_known.contains(n.id)).toList();
      items = fetched;
      _known
        ..clear()
        ..addAll(fetched.map((n) => n.id));

      // Solo se alerta de lo que llega DESPUÉS de la primera consulta, y solo
      // si el usuario tiene las notificaciones activadas.
      if (_firstLoadDone && nuevos.isNotEmpty && ProfileController.instance.notifications.enabled) {
        AppMessenger.info(
          nuevos.length == 1 ? 'Tienes un aviso nuevo' : 'Tienes ${nuevos.length} avisos nuevos',
          message: nuevos.first.title,
        );
      }
      _firstLoadDone = true;
    } catch (e) {
      error = e is DataException ? e.message : 'No se pudieron cargar tus avisos.';
      AppLog.error('NotificationsController.load', e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final id = _userId;
    if (id == null) return;
    final i = items.indexWhere((n) => n.id == notificationId);
    if (i < 0 || items[i].read) return;
    items[i] = items[i].copyWith(read: true); // la interfaz responde de inmediato
    notifyListeners();
    try {
      await AppServices.notifications.markAsRead(id, notificationId);
    } catch (e) {
      items[i] = items[i].copyWith(read: false); // se revierte
      notifyListeners();
      AppMessenger.error('No se pudo marcar el aviso como leído');
      AppLog.error('NotificationsController.markAsRead', e);
    }
  }

  Future<void> markAllAsRead() async {
    final id = _userId;
    if (id == null || !hasUnread) return;
    final previos = [...items];
    items = [for (final n in items) n.copyWith(read: true)];
    notifyListeners();
    try {
      await AppServices.notifications.markAllAsRead(id);
    } catch (e) {
      items = previos;
      notifyListeners();
      AppMessenger.error('No se pudieron marcar los avisos');
      AppLog.error('NotificationsController.markAllAsRead', e);
    }
  }

  /// Al cerrar sesión: la siguiente cuenta no debe ver los avisos de la anterior.
  void reset() {
    items = [];
    _known.clear();
    _firstLoadDone = false;
    loading = false;
    error = null;
    notifyListeners();
  }
}
