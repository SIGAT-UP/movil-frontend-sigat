import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';
import 'profile_controller.dart';

/// M13-T — Preferencias de notificaciones del usuario autenticado.
///
/// El interruptor guarda la PREFERENCIA de la persona. No pide permisos al
/// sistema operativo ni los modifica: cuando existan notificaciones push,
/// el permiso de Android, iOS o el navegador se gestionará por separado.
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final _ctrl = ProfileController.instance;

  @override
  void initState() {
    super.initState();
    _ctrl.clearMessages();
    if (_ctrl.profile == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ctrl.load());
    }
  }

  Future<void> _toggle(bool value) async {
    final ok = await _ctrl.setNotificationsEnabled(value);
    if (!mounted || ok) return;
    AppMessenger.error('No se pudo guardar la preferencia', message: _ctrl.error ?? 'Intenta de nuevo.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SimpleAppBar(title: 'Preferencias'),
      body: ListenableBuilder(
        listenable: _ctrl,
        builder: (context, _) {
          if (_ctrl.loading && _ctrl.profile == null) return const AppLoader();
          final prefs = _ctrl.notifications;
          return ResponsiveBody(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screenH),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text('Recibir notificaciones', style: AppText.title),
                          ),
                          if (_ctrl.savingNotifications)
                            const Padding(
                              padding: EdgeInsets.only(right: AppSpacing.sm),
                              child: AppInlineLoader(size: 16, color: AppColors.primary),
                            ),
                          Switch(
                            value: prefs.enabled,
                            activeThumbColor: AppColors.primary,
                            onChanged: _ctrl.savingNotifications ? null : _toggle,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      const Text(
                        'Avisos de la aplicación sobre tus visitas, tus lotes y el estado de la '
                        'sincronización.',
                        style: AppText.secondary,
                      ),
                      const Divider(height: AppSpacing.xl, color: AppColors.divider),
                      Row(
                        children: [
                          const Text('Estado actual', style: AppText.secondary),
                          const Spacer(),
                          StatusBadge(
                            prefs.label,
                            tone: prefs.enabled ? StatusTone.success : StatusTone.neutral,
                            icon: prefs.enabled ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_ctrl.error != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  AlertBanner(title: 'No se pudo guardar', message: _ctrl.error),
                ],
                const SizedBox(height: AppSpacing.lg),
                const AlertBanner(
                  type: AlertType.info,
                  title: 'Esta es tu preferencia dentro de la app',
                  message: 'El permiso para mostrar notificaciones lo concede el sistema del dispositivo '
                      'y se gestiona aparte. El envío de notificaciones todavía no está implementado.',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
