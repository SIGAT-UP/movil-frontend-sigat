import 'package:flutter/material.dart';

import '../../app/shell_nav.dart';
import '../../core/widgets/widgets.dart';
import 'activity_timeline.dart';
import 'producer_controller.dart';

/// P02-P — Estado de mi cultivo (pestaña "Mi cultivo").
class CropStatusScreen extends StatelessWidget {
  const CropStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = ProducerController.instance;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: SimpleAppBar(
        title: 'Estado de mi cultivo',
        onBack: () => ProducerNav.tab.value = ProducerTab.inicio,
      ),
      body: ListenableBuilder(
        listenable: ctrl,
        builder: (context, _) {
          final s = ctrl.summary;
          if (s == null) {
            return ctrl.error != null
                ? EmptyState(
                    icon: Icons.cloud_off,
                    title: 'No se pudo cargar tu cultivo',
                    action: SecondaryButton(label: 'Reintentar', onPressed: ctrl.load),
                  )
                : const AppLoader();
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: ctrl.load,
            child: ResponsiveBody(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.screenH),
                children: [
                  InfoTableCard(rows: [
                    InfoRowData('Cultivo', value: s.crop),
                    InfoRowData('Última visita', value: s.lastVisit == null ? 'Sin visitas' : Fmt.date(s.lastVisit!)),
                    InfoRowData('Lotes revisados', value: '${s.lotsReviewed}'),
                    InfoRowData(
                      'Estado',
                      trailing: s.vigilanceActive
                          ? const StatusBadge('Vigilancia activa', icon: Icons.check)
                          : const StatusBadge('Vigilancia inactiva', tone: StatusTone.neutral),
                    ),
                    InfoRowData(
                      'Última aplicación',
                      value: s.lastApplication == null ? 'Sin aplicaciones' : Fmt.ago(s.lastApplication!),
                    ),
                  ]),
                  const SizedBox(height: AppSpacing.xl),
                  const SectionTitle('Actividad reciente'),
                  const SizedBox(height: AppSpacing.md),
                  ActivityTimeline(records: ctrl.activity.take(3).toList()),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
