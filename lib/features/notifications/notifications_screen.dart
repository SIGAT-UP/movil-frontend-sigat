import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/widgets/widgets.dart';
import '../../data/app_services.dart';
import '../../data/models/app_notification.dart';
import '../../data/models/user_profile.dart';
import '../profile/profile_controller.dart';
import 'notifications_controller.dart';

/// Notificaciones del usuario autenticado: asignaciones y avisos del sistema.
/// Es la ÚNICA bandeja de la app: la abren la campana de cada inicio y, en el
/// técnico, la opción "Notificaciones" de la pestaña Más.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _ctrl = NotificationsController.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ctrl.load());
  }

  /// Abre el contenido relacionado, comprobando antes que el rol tenga permiso.
  Future<void> _open(AppNotification n) async {
    await _ctrl.markAsRead(n.id);
    if (!mounted) return;
    final target = n.target;
    if (target == null) return;

    final role = AppServices.session.value?.role;
    if (!AppRoutes.canAccess(target.route, role)) {
      AppMessenger.warning(
        'No tienes acceso a este contenido',
        message: 'Tu rol no permite abrir esa pantalla.',
      );
      return;
    }
    Navigator.of(context).pushNamed(target.route, arguments: target.argument);
  }

  bool get _puedeConfigurar =>
      AppRoutes.canAccess(AppRoutes.profileNotifications, AppServices.session.value?.role);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: SimpleAppBar(
        title: 'Notificaciones',
        actions: [
          // Preferencias: solo para los roles que tienen esa pantalla.
          if (_puedeConfigurar)
            AppIconButton(
              icon: Icons.tune,
              tooltip: 'Preferencias de notificaciones',
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.profileNotifications),
            ),
          ListenableBuilder(
            listenable: _ctrl,
            builder: (_, __) => TextButton(
              onPressed: _ctrl.hasUnread ? _ctrl.markAllAsRead : null,
              child: const Text('Marcar todas'),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([_ctrl, ProfileController.instance]),
        builder: (context, _) {
          if (_ctrl.loading && _ctrl.items.isEmpty) return const AppLoader();

          if (_ctrl.error != null && _ctrl.items.isEmpty) {
            return EmptyState(
              icon: Icons.cloud_off,
              title: 'No se pudieron cargar tus notificaciones',
              message: _ctrl.error,
              action: SecondaryButton(label: 'Reintentar', onPressed: _ctrl.load),
            );
          }

          if (_ctrl.items.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none,
              title: 'No tienes notificaciones',
              message: 'Aquí verás las asignaciones y los avisos que te envíe el sistema.',
            );
          }

          final prefsOff = !ProfileController.instance.notifications.enabled;

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _ctrl.load,
            child: ResponsiveBody(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.screenH),
                children: [
                  if (prefsOff) ...[
                    const AlertBanner(
                      type: AlertType.warning,
                      title: 'Tienes las notificaciones desactivadas',
                      message: 'Siguen llegando aquí, pero no verás alertas emergentes. '
                          'Puedes cambiarlo con el botón de preferencias, arriba a la derecha.',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  for (final n in _ctrl.items) ...[
                    _NotificationCard(notification: n, onTap: () => _open(n)),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  StatusTone get _tone => switch (notification.category) {

        NotificationCategory.asignacion => StatusTone.success,
        NotificationCategory.alertasFitosanitarias => StatusTone.error,
        NotificationCategory.recordatoriosInspeccion => StatusTone.warning,
        NotificationCategory.avisosPredio => StatusTone.info,
        NotificationCategory.sincronizacion => StatusTone.neutral,
        NotificationCategory.solicitudesCuenta => StatusTone.info,
      };

  @override
  Widget build(BuildContext context) {
    final noLeido = !notification.read;
    return AppCard(
      onTap: onTap,
      tone: noLeido ? AppCardTone.highlighted : AppCardTone.normal,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: noLeido ? AppColors.primary : AppColors.border,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusBadge(notification.category.label, tone: _tone),
                    const Spacer(),
                    Text(Fmt.ago(notification.createdAt), style: AppText.micro),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  notification.title,
                  style: noLeido ? AppText.title : AppText.title.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(notification.body, style: AppText.secondary),
              ],
            ),
          ),
          if (notification.target != null)
            const Padding(
              padding: EdgeInsets.only(left: AppSpacing.sm),
              child: Icon(Icons.chevron_right, color: AppColors.textHint),
            ),
        ],
      ),
    );
  }
}

/// Campana con el número de avisos sin leer. Se usa en los encabezados de inicio.
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => NotificationsController.instance.load());
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: NotificationsController.instance,
      builder: (context, _) {
        final count = NotificationsController.instance.unreadCount;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            AppIconButton(
              icon: count > 0 ? Icons.notifications_active_outlined : Icons.notifications_none,
              tooltip: count > 0 ? '$count notificaciones sin leer' : 'Notificaciones',
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.notifications),
            ),
            if (count > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    style: AppText.micro.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 9,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
