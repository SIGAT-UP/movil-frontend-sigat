import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../app/shell_nav.dart';
import '../../data/models/user_session.dart';
import '../../core/widgets/widgets.dart';
import '../../data/app_services.dart';
import '../../data/models/photo_file.dart';
import '../../data/photo_service.dart';
import '../../shared/shared.dart';
import '../auth/logout.dart';
import '../notifications/notifications_controller.dart';
import '../visit/visit_controller.dart';
import 'profile_controller.dart';
import 'profile_photo_screen.dart';

/// Perfil y ajustes de TODOS los roles (técnico: pestaña "Más"; productor y agrónomo:
/// pestaña "Perfil"). La foto, las notificaciones, la conexión y el cierre de sesión son
/// comunes; los accesos directos cambian según el rol ([_accesosDelRol]).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _ctrl = ProfileController.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ctrl.load());
  }

  /// Cambiar foto: elegir origen → validar → previsualizar → confirmar.
  /// Cancelar en cualquier paso deja el perfil como estaba.
  Future<void> _changePhoto() async {
    while (mounted) {
      final choice = await showPhotoSourceSheet(
        context,
        title: 'Fotografía de perfil',
        message: 'Se verá en tu perfil dentro de la aplicación.',
        allowRemove: _ctrl.profile?.hasPhoto ?? false,
        isWeb: PhotoService.instance.cameraIsFilePickerOnWeb,
      );
      if (choice == null || !mounted) return;

      if (choice == PhotoSourceChoice.quitar) {
        final ok = await showAppConfirmDialog(
          context,
          title: 'Quitar fotografía',
          message: 'Volverás a ver tus iniciales en el perfil.',
          confirmLabel: 'Quitar',
          destructive: true,
        );
        if (ok && mounted) {
          await _ctrl.removePhoto();
          _showMessages();
        }
        return;
      }

      final source = choice == PhotoSourceChoice.camara ? PhotoSource.camara : PhotoSource.galeria;
      PhotoFile? photo;
      try {
        photo = await PhotoService.instance.pick(source);
      } on PhotoException catch (e) {
        if (!mounted) return;
        AppMessenger.warning('No se puede usar esa imagen', message: e.message);
        continue; // deja reintentar
      }
      if (photo == null || !mounted) return;

      final result = await Navigator.of(context).pushNamed(AppRoutes.profilePhoto, arguments: photo);
      if (!mounted) return;
      if (result is ProfilePhotoResult) {
        if (result.changeSource) continue;
        if (result.photo != null) {
          await _ctrl.setPhoto(result.photo!);
          _showMessages();
          return;
        }
      }
      return;
    }
  }

  /// La foto solo se anuncia como "actualizada" si el servidor la confirmó.
  /// Mientras no haya backend se informa que quedó pendiente de enviar.
  void _showMessages() {
    if (!mounted) return;
    if (_ctrl.error != null) {
      AppMessenger.error('No se pudo actualizar la fotografía', message: _ctrl.error);
    } else if (_ctrl.notice != null) {
      final confirmada = _ctrl.profile?.photoStatus == UploadStatus.uploaded;
      final sinFoto = !(_ctrl.profile?.hasPhoto ?? false);
      if (confirmada || sinFoto) {
        AppMessenger.success(_ctrl.notice!);
      } else {
        AppMessenger.pending('Fotografía guardada', message: _ctrl.notice);
      }
    }
    _ctrl.clearMessages();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppServices.session.value;
    final lots = VisitController.instance.assignedLots.length;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SimpleAppBar(title: 'Mi perfil', showBack: false),
      body: ListenableBuilder(
        listenable: _ctrl,
        builder: (context, _) {
          final profile = _ctrl.profile;
          return ResponsiveBody(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screenH),
              children: [
                Center(
                  child: UserAvatar(
                    name: s?.displayName ?? '',
                    photoBytes: profile?.photoBytes,
                    isBusy: _ctrl.savingPhoto,
                    onEdit: _changePhoto,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: AppLinkButton(
                    label: profile?.hasPhoto ?? false ? 'Cambiar foto' : 'Agregar foto',
                    fontSize: 13,
                    onPressed: _ctrl.savingPhoto ? null : _changePhoto,
                  ),
                ),
                if (profile?.photoPendingUpload ?? false) ...[
                  const SizedBox(height: AppSpacing.xs),
                  const Center(
                    child: RecordStatusBadge(RecordStatus.local, label: 'Foto pendiente de enviar'),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Center(child: Text(s?.shortName ?? '', style: AppText.h2)),
                Center(child: Text(_subtitulo(s?.role), style: AppText.secondary)),
                const SizedBox(height: AppSpacing.xl),
                MenuTile(icon: Icons.mail_outline, title: s?.username ?? '', iconColor: AppColors.info),
                const SizedBox(height: 8),
                for (final tile in _accesosDelRol(context, s?.role, lots)) ...[tile, const SizedBox(height: 8)],
                // Una sola entrada: abre la bandeja. Las preferencias están
                // dentro de la bandeja (botón de ajustes en la barra superior).
                ListenableBuilder(
                  listenable: Listenable.merge([NotificationsController.instance, _ctrl]),
                  builder: (_, __) {
                    final sinLeer = NotificationsController.instance.unreadCount;
                    final activas = _ctrl.notifications.enabled;
                    return MenuTile(
                      icon: activas ? Icons.notifications_none : Icons.notifications_off_outlined,
                      title: 'Notificaciones',
                      subtitle: sinLeer > 0
                          ? '$sinLeer sin leer'
                          : (activas ? 'Asignaciones y avisos del sistema' : 'Alertas emergentes desactivadas'),
                      iconColor: AppColors.warningStrong,
                      trailing: sinLeer == 0 ? null : StatusBadge('$sinLeer', tone: StatusTone.error),
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.notifications),
                    );
                  },
                ),
                const SizedBox(height: 8),
                const MenuTile(icon: Icons.language, title: 'Idioma', subtitle: 'Español', iconColor: AppColors.info),
                const SizedBox(height: 8),
                const MenuTile(
                  icon: Icons.info_outline,
                  title: 'Versión de la app',
                  subtitle: 'v1.0.0',
                  iconColor: AppColors.textSecondary,
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<bool>(
                  valueListenable: AppServices.isOnline,
                  builder: (_, online, __) => MenuTile(
                    icon: online ? Icons.wifi : Icons.wifi_off,
                    title: 'Conexión',
                    subtitle: online ? 'Conectado' : 'Sin conexión · los datos se guardan en el dispositivo',
                    iconColor: online ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                DestructiveButton(label: 'Cerrar sesión', onPressed: () => confirmAndLogout(context)),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Descripción del perfil y su función dentro de SIGAT.
  static String _subtitulo(UserRole? role) => switch (role) {
        UserRole.productor => 'Productor · Vigilancia Fitosanitaria',
        UserRole.agronomo => 'Agrónomo / Supervisor · Vigilancia Fitosanitaria',
        null => '',
        final r => '${r.label} · Vigilancia Fitosanitaria',
      };

  /// Accesos directos propios de cada rol (solo a pantallas que ese rol puede abrir).
  List<Widget> _accesosDelRol(BuildContext context, UserRole? role, int lots) {
    void abrir(String ruta) => Navigator.of(context).pushNamed(ruta);
    return switch (role) {
      UserRole.productor => [
          MenuTile(
            icon: Icons.eco_outlined,
            title: 'Mi cultivo',
            subtitle: 'Estado de tus lotes y vigilancia',
            onTap: () => ProducerNav.goTo(context, ProducerTab.cultivo),
          ),
          MenuTile(
            icon: Icons.history,
            title: 'Historial',
            subtitle: 'Visitas, aplicaciones y cosechas',
            onTap: () => ProducerNav.goTo(context, ProducerTab.historial),
          ),
          MenuTile(
            icon: Icons.assignment_outlined,
            title: 'Planificaciones',
            subtitle: 'Las que te envió el agrónomo',
            onTap: () => abrir(AppRoutes.planningList),
          ),
          MenuTile(
            icon: Icons.sync,
            title: 'Sincronización',
            subtitle: 'Enviar aplicaciones y cosechas guardadas',
            onTap: () => abrir(AppRoutes.producerSync),
          ),
        ],
      UserRole.agronomo => [
          MenuTile(
            icon: Icons.eco_outlined,
            title: 'Lote de durazno',
            subtitle: 'Datos y control vigente',
            onTap: () => abrir(AppRoutes.agroLotInfo),
          ),
          MenuTile(
            icon: Icons.insights_outlined,
            title: 'Resumen del lote',
            subtitle: 'Tendencia del MTD e indicadores',
            onTap: () => abrir(AppRoutes.agroLotSummary),
          ),
          MenuTile(
            icon: Icons.fact_check_outlined,
            title: 'Registros por revisar',
            onTap: () => AgronomistNav.goTo(context, AgronomistTab.revisiones),
          ),
          MenuTile(
            icon: Icons.calendar_month_outlined,
            title: 'Planeación',
            subtitle: 'Planeaciones y asignaciones de lotes',
            onTap: () => abrir(AppRoutes.agroPlanningHub),
          ),
          MenuTile(
            icon: Icons.tune,
            title: 'Programa de inspección',
            subtitle: 'Escenarios de trampeo (solo consulta)',
            onTap: () => abrir(AppRoutes.agroConfig),
          ),
        ],
      _ => [
          MenuTile(
            icon: Icons.location_on_outlined,
            title: 'Lotes asignados',
            subtitle: lots == 0 ? 'Ver lotes' : '$lots lotes',
            onTap: () => abrir(AppRoutes.lots),
          ),
          MenuTile(
            icon: Icons.history,
            title: 'Historial de visitas',
            onTap: () => abrir(AppRoutes.history),
          ),
          MenuTile(
            icon: Icons.sync,
            title: 'Sincronización',
            subtitle: 'Enviar registros guardados',
            onTap: () => abrir(AppRoutes.sync),
          ),
        ],
    };
  }
}



