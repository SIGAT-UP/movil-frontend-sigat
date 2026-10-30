import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';
import 'agronomist_controller.dart';
import '../../shared/shared.dart';

/// Lote de durazno: ficha del lote y control vigente.
/// Si un dato no está disponible se muestra "Sin registrar".
class LotInfoScreen extends StatefulWidget {
  const LotInfoScreen({super.key});

  @override
  State<LotInfoScreen> createState() => _LotInfoScreenState();
}

class _LotInfoScreenState extends State<LotInfoScreen> {
  final _ctrl = AgronomistController.instance;

  @override
  void initState() {
    super.initState();
    if (_ctrl.lot == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ctrl.load());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SimpleAppBar(title: 'Lote de durazno'),
      body: ListenableBuilder(
        listenable: _ctrl,
        builder: (context, _) {
          final lot = _ctrl.lot;
          if (lot == null && _ctrl.loadError != null && !_ctrl.loading) {
            return ErrorState(error: _ctrl.loadError, what: 'el lote', onRetry: _ctrl.load);
          }
          if (lot == null) return const AppLoader();
          final control = lot.control;
          return ResponsiveBody(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screenH),
              children: [
                InfoTableCard(rows: [
                  InfoRowData('Propietario', value: lot.owner.isEmpty ? 'Sin registrar' : lot.owner),
                  InfoRowData('Cultivo', value: lot.crop),
                  InfoRowData('Área', value: '${Fmt.decimal(lot.areaHa)} ha'),
                  InfoRowData(
                    'Estado',
                    trailing: lot.vigilanceActive
                        ? const StatusBadge('Activa', icon: Icons.check)
                        : const StatusBadge('Inactiva', tone: StatusTone.neutral),
                  ),
                  InfoRowData('Número de trampas', value: '${lot.trapCount}'),
                  InfoRowData(
                    'Última visita',
                    value: lot.lastVisit == null ? 'Sin registrar' : Fmt.date(lot.lastVisit!),
                  ),
                ]),
                const SizedBox(height: AppSpacing.lg),
                if (control == null)
                  const AppCard(
                    tone: AppCardTone.highlighted,
                    child: Text('Control vigente sin registrar', style: AppText.secondary),
                  )
                else
                  InfoTableCard(
                    title: 'Control vigente',
                    highlighted: true,
                    showDividers: false,
                    footer: control.note,
                    rows: [
                      InfoRowData('MTD (último periodo cerrado)',
                          value: '${Fmt.fixed(control.mtd, 2)} moscas/trampa/día'),
                      InfoRowData('Umbral de exportación', value: control.exportThreshold),
                      InfoRowData('Concepto de aptitud', value: control.aptitude),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
