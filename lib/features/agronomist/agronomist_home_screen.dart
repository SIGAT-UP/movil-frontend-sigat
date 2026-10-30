import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/widgets/widgets.dart';
import '../../data/app_services.dart';
import '../auth/logout.dart';
import '../notifications/notifications_screen.dart';
import 'agronomist_controller.dart';

/// MA01 — Inicio del Agrónomo.
class AgronomistHomeScreen extends StatefulWidget {
  const AgronomistHomeScreen({super.key});

  @override
  State<AgronomistHomeScreen> createState() => _AgronomistHomeScreenState();
}

class _AgronomistHomeScreenState extends State<AgronomistHomeScreen> {
  final _ctrl = AgronomistController.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ctrl.load());
  }

  @override
  Widget build(BuildContext context) {
    final s = AppServices.session.value;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([_ctrl, AppServices.isOnline]),
          builder: (context, _) {
            final resumen = _ctrl.summary;
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _ctrl.load,
              child: ResponsiveBody(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.screenH),
                  children: [
                    // --- Saludo ---
                    GreetingHeader(
                      title: 'Hola Agro. ${s?.shortName ?? ''}',
                      subtitle: 'Lote de durazno · Agrónomo',
                      titleStyle: AppText.h2,
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

                    // --- Estado actual del lote ---
                    if (_ctrl.loading && resumen == null)
                      const AppLoader(padding: EdgeInsets.all(AppSpacing.xl))
                    else if (resumen == null)
                      AlertBanner(
                        title: 'No se pudo cargar el estado del lote',
                        message: _ctrl.error ?? 'Desliza hacia abajo para reintentar.',
                      )
                    else
                      AppCard(
                        tone: AppCardTone.highlighted,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Estado actual', style: AppText.caption),
                            const SizedBox(height: 2),
                            Text('Escenario: ${resumen.scenario.toLowerCase()}',
                                style: AppText.h1.copyWith(color: AppColors.primaryDark)),
                            const SizedBox(height: AppSpacing.md),
                            InfoRow(
                              InfoRowData(
                                'MTD (último periodo cerrado)',
                                value: resumen.mtd == null ? 'Sin cálculo' : Fmt.fixed(resumen.mtd!, 2),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 6),
                            ),
                            InfoRow(
                              InfoRowData('Umbral de exportación', value: resumen.exportThreshold),
                              padding: const EdgeInsets.symmetric(vertical: 6),
                            ),
                            InfoRow(
                              InfoRowData('Concepto de aptitud', value: resumen.aptitudeConcept),
                              padding: const EdgeInsets.symmetric(vertical: 6),
                            ),
                            const Text('moscas / trampa / día', style: AppText.micro),
                          ],
                        ),
                      ),
                    const SizedBox(height: AppSpacing.lg),

                    // --- Requiere revisión ---
                    AppCard(
                      color: AppColors.warningLight,
                      borderColor: AppColors.warningBorder,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  size: AppIconSize.md, color: AppColors.warningText),
                              const SizedBox(width: AppSpacing.sm),
                              Text('Requiere revisión',
                                  style: AppText.title.copyWith(color: AppColors.warningText)),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            _ctrl.pendingCount == 0
                                ? 'No hay visitas pendientes de revisión'
                                : '${_ctrl.pendingCount} visitas pendientes',
                            style: AppText.secondary,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          PrimaryButton(
                            label: 'Ver registros',
                            color: AppColors.primaryDark,
                            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.agroRecords),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // --- Accesos ---
                    MenuTile(
                      icon: Icons.eco_outlined,
                      title: 'Lote de durazno',
                      subtitle: 'Datos y control vigente',
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.agroLotInfo),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    MenuTile(
                      icon: Icons.insights_outlined,
                      title: 'Resumen del lote',
                      subtitle: 'Tendencia y actividad reciente',
                      iconColor: AppColors.info,
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.agroLotSummary),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    MenuTile(
                      icon: Icons.settings_outlined,
                      title: 'Configuración',
                      subtitle: 'Programa, trampas y umbral',
                      iconColor: AppColors.warningStrong,
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.agroConfig),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    MenuTile(
                      icon: Icons.event_note_outlined,
                      title: 'Planeación',
                      subtitle: 'Planeación y asignación de lotes',
                      iconColor: AppColors.primaryDark,
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.agroPlanningHub),
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
