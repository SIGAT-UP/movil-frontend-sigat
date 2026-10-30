import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../app/shell_nav.dart';
import '../../core/widgets/widgets.dart';
import '../../data/app_services.dart';
import 'visit_controller.dart';

/// M08-T — Finalizar visita. Solo se habilita si TODOS los lotes asignados están finalizados.
class FinishVisitScreen extends StatefulWidget {
  const FinishVisitScreen({super.key});

  @override
  State<FinishVisitScreen> createState() => _FinishVisitScreenState();
}

class _FinishVisitScreenState extends State<FinishVisitScreen> {
  final _visit = VisitController.instance;
  late final Future<(int, int)> _counts = _loadCounts();
  bool _busy = false;

  /// (lecturas guardadas en ESTA visita, pendientes de sincronizar)
  Future<(int, int)> _loadCounts() async {
    final pending = (await AppServices.sync.getPending()).length;
    return (_visit.readingsThisVisit, pending);
  }

  Future<void> _finish() async {
    setState(() => _busy = true);
    await _visit.finishVisit();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.sync);
  }

  @override
  Widget build(BuildContext context) {
    final can = _visit.canFinishVisit;
    final left = _visit.lotsTotal - _visit.lotsDone;
    return Scaffold(
      appBar: const SimpleAppBar(title: 'Finalizar visita'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenH),
        children: [
          FutureBuilder<(int, int)>(
            future: _counts,
            builder: (_, snap) => ValueListenableBuilder<bool>(
              valueListenable: AppServices.isOnline,
              builder: (_, online, __) => InfoTableCard(
                title: 'Resumen de la visita',
                rows: [
                  InfoRowData('Lotes registrados', value: '${_visit.lotsDone}/${_visit.lotsTotal}'),
                  InfoRowData('Lecturas guardadas', value: snap.hasData ? '${snap.data!.$1}' : (snap.hasError ? 'No disponible' : '…')),
                  InfoRowData('Pendientes de sincronización', value: snap.hasData ? '${snap.data!.$2}' : (snap.hasError ? 'No disponible' : '…')),
                  InfoRowData('Conexión', trailing: ConnectionChip(isOnline: online)),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (can)
            const AlertBanner(
              type: AlertType.info,
              title: 'Puedes finalizar la visita',
              message: 'Los datos permanecerán guardados hasta que exista conexión.',
            )
          else
            AlertBanner(
              title: 'Aún no puedes finalizar la visita',
              message: 'Te falta(n) $left lote(s) asignado(s) por finalizar.',
            ),
        ],
      ),
      bottomNavigationBar: BottomActions(children: [
        PrimaryButton(
          label: 'Finalizar visita',
          loadingLabel: 'Finalizando...',
          isLoading: _busy,
          color: AppColors.primaryDark,
          onPressed: can ? _finish : null,
        ),
        SecondaryButton(label: 'Volver al menú', onPressed: () => ShellNav.goTo(context, AppTab.inicio)),
      ]),
    );
  }
}
