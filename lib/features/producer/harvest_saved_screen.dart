import 'package:flutter/material.dart';

import '../../app/shell_nav.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/producer.dart';
import '../../shared/shared.dart';

/// P04b-P — Cosecha registrada.
class HarvestSavedScreen extends StatelessWidget {
  const HarvestSavedScreen({super.key, required this.report});
  final HarvestReport report;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: SimpleAppBar(
        title: 'Cosecha',
        onBack: () => ProducerNav.goTo(context, ProducerTab.inicio),
      ),
      body: ResponsiveBody(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenH),
          children: [
            const SizedBox(height: AppSpacing.lg),
            const SuccessHero(
              title: 'Cosecha registrada',
              message: 'Tu autorreporte se ha guardado localmente.',
            ),
            const SizedBox(height: AppSpacing.xl),
            InfoTableCard(rows: [
              InfoRowData('Fecha estimada', value: Fmt.dateNumeric(report.expectedDate)),
              InfoRowData('Fecha real',
                  value: report.actualDate == null ? '— (pendiente)' : Fmt.dateNumeric(report.actualDate!)),
              InfoRowData('Volumen', value: '${Fmt.decimal(report.volumeKg)} kg'),
            ]),
            const SizedBox(height: AppSpacing.lg),
            const Center(child: RecordStatusBadge(RecordStatus.pendiente, label: 'Pendiente de sincronizar')),
          ],
        ),
      ),
      bottomNavigationBar: BottomActions(children: [
        PrimaryButton(
          label: 'Volver al inicio',
          color: AppColors.primaryDark,
          onPressed: () => ProducerNav.goTo(context, ProducerTab.inicio),
        ),
        SecondaryButton(
          label: 'Ver historial',
          onPressed: () => ProducerNav.goTo(context, ProducerTab.historial),
        ),
      ]),
    );
  }
}
