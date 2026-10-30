import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/widgets/widgets.dart';
import '../../data/app_services.dart';
import '../../shared/shared.dart';
import '../auth/logout.dart';
import '../notifications/notifications_screen.dart';
import '../planning/planning_inbox_card.dart';
import '../sync/sync_controller.dart';
import 'producer_controller.dart';

/// P01-P — Inicio del productor.
class ProducerHomeScreen extends StatefulWidget {
  const ProducerHomeScreen({super.key});

  @override
  State<ProducerHomeScreen> createState() => _ProducerHomeScreenState();
}

class _ProducerHomeScreenState extends State<ProducerHomeScreen> {
  final _ctrl = ProducerController.instance;
  final _sync = SyncController.instance;

  @override
  void initState() {
    super.initState();
    // Se carga después del primer frame: avisar a otros widgets durante el build no está permitido.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ctrl.load();
      _sync.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = AppServices.session.value;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([_ctrl, _sync, AppServices.isOnline]),
          builder: (context, _) {
            final s = _ctrl.summary;
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => Future.wait([_ctrl.load(), _sync.load()]),
              child: ResponsiveBody(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.screenH),
                  children: [
                    // Encabezado
                    GreetingHeader(
                      title: 'Mi cultivo',
                      subtitle: 'Hola Prod. ${session?.shortName ?? ''}',
                      isOnline: AppServices.isOnline.value,
                      actions: [
                        const NotificationBell(),
                        AppIconButton(
                          icon: Icons.logout,
                          tooltip: 'Cerrar sesión',
                          onPressed: () => confirmAndLogout(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Tarjeta del cultivo
                    if (_ctrl.error != null && s == null)
                      AlertBanner(
                        title: 'No se pudo cargar tu cultivo',
                        message: '${_ctrl.error} Desliza hacia abajo para reintentar.',
                      )
                    else if (s == null)
                      const AppLoader(padding: EdgeInsets.all(AppSpacing.xl))
                    else
                      AppCard(
                        tone: AppCardTone.highlighted,
                        borderColor: AppColors.primary,
                        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xs),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration:
                                      const BoxDecoration(color: AppColors.primaryDark, shape: BoxShape.circle),
                                  child: const Icon(Icons.eco_outlined, color: Colors.white, size: AppIconSize.md),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(s.crop, style: AppText.h3),
                                      Text(s.lotLabel, style: AppText.caption),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            s.vigilanceActive
                                ? const StatusBadge('Vigilancia activa', icon: Icons.check)
                                : const StatusBadge('Vigilancia inactiva', tone: StatusTone.neutral),
                            const SizedBox(height: AppSpacing.xs),
                            InfoRow(InfoRowData('Última visita',
                                value: s.lastVisit == null ? 'Sin visitas' : Fmt.date(s.lastVisit!))),
                            InfoRow(InfoRowData('Estado del cultivo', value: s.cropStatus)),
                            InfoRow(InfoRowData(
                              'Último resultado',
                              trailing: MtdIndicator(
                                value: s.lastMtd,
                                compact: true,
                                note: '(si existe un cálculo válido)',
                              ),
                            )),
                          ],
                        ),
                      ),
                    const SizedBox(height: AppSpacing.md),
                    const PlanningInboxCard(
                      subtitle: 'Planeaciones que te envió el agrónomo',
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Acciones
                    PrimaryButton(
                      label: 'Registrar aplicación',
                      color: AppColors.primaryDark,
                      onPressed: () => Navigator.of(context).pushNamed(AppRoutes.producerApplication),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SecondaryButton(
                      label: 'Registrar cosecha',
                      onPressed: () => Navigator.of(context).pushNamed(AppRoutes.producerHarvest),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Center(
                      child: PrimaryButton(
                        label: 'Sincronizar ahora',
                        icon: Icons.sync,
                        expand: false,
                        color: AppColors.primaryDark,
                        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.producerSync),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Center(
                      child: Text(
                        _sync.pendingCount == 0
                            ? 'No tienes registros pendientes'
                            : '${_sync.pendingCount} registro(s) pendiente(s) de sincronizar',
                        style: AppText.caption,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
