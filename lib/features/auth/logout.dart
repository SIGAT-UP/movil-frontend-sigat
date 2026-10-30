import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../app/shell_nav.dart';
import '../../core/utils/app_log.dart';
import '../../core/widgets/widgets.dart';
import '../../data/app_services.dart';
import '../agronomist/agronomist_controller.dart';
import '../notifications/notifications_controller.dart';
import '../planning/planning_inbox_controller.dart';
import '../producer/producer_controller.dart';
import '../profile/profile_controller.dart';
import '../sync/sync_controller.dart';
import '../visit/visit_controller.dart';

/// Cierre de sesión común a todos los roles: confirma, limpia el estado en memoria
/// y vuelve al login. Los datos sin sincronizar NO se borran del dispositivo.
Future<void> confirmAndLogout(BuildContext context) async {
  final ok = await showAppConfirmDialog(
    context,
    title: 'Cerrar sesión',
    message: 'Los datos sin sincronizar permanecen guardados en el dispositivo.',
    confirmLabel: 'Cerrar sesión',
    destructive: true,
  );
  if (!ok || !context.mounted) return;
  await logoutNow(context);
}

/// Cierra la sesión SIN preguntar. Lo usa el botón atrás del contexto de
/// acceso: ahí todavía no hay nada que perder.
Future<void> logoutNow(BuildContext context) async {
  try {
    // Avisa al servidor y borra los tokens del almacenamiento seguro. Si el servidor no
    // responde, los tokens se borran igual (ver ApiAuthRepository.logout).
    await AppServices.auth.logout();
  } catch (e, st) {
    AppLog.error('logout', e, st);
  } finally {
    // Pase lo que pase con la red o el almacenamiento, la sesión en memoria se cierra.
    // La cola de pendientes NO se toca: cada registro conserva su dueño.
    clearSessionState();
  }
  if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
}

/// Olvida la sesión y el estado en memoria de todos los roles, sin navegar.
/// La usa [logoutNow] y también las pruebas, para que cada una empiece de cero.
void clearSessionState() {
  AppServices.session.value = null;
  VisitController.instance.reset();
  ProducerController.instance.reset();
  ProfileController.instance.reset();
  NotificationsController.instance.reset();
  SyncController.instance.reset();
  AgronomistController.instance.reset();
  PlanningInboxController.instance.reset();
  ShellNav.nav.reset();
  ProducerNav.nav.reset();
  AgronomistNav.nav.reset();
}
