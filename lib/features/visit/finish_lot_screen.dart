import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../app/shell_nav.dart';
import '../../core/widgets/widgets.dart';
import '../../data/app_services.dart';
import '../../data/models/trap.dart';
import 'visit_controller.dart';

/// M08-T — Finalizar lote.
class FinishLotScreen extends StatefulWidget {
  const FinishLotScreen({super.key});

  @override
  State<FinishLotScreen> createState() => _FinishLotScreenState();
}

class _FinishLotScreenState extends State<FinishLotScreen> {
  final _visit = VisitController.instance;
  late final Future<int> _pendingSync = AppServices.sync.getPending().then((l) => l.length);
  bool _busy = false;

  Future<void> _finish() async {
    final nav = Navigator.of(context);
    final lotName = _visit.activeLot?.name ?? 'Lote';
    setState(() => _busy = true);
    final allDone = await _visit.finishLot();
    if (!mounted) return;
    setState(() => _busy = false);

    if (allDone) {
      nav.pushReplacementNamed(AppRoutes.finishVisit);
    } else {
      final left = _visit.lotsTotal - _visit.lotsDone;
      // El lote quedó cerrado en el dispositivo; el envío al servidor es aparte.
      AppMessenger.pending('$lotName finalizado',
          message: 'Te falta(n) $left lote(s) para terminar la visita.');
      ShellNav.goTo(context, AppTab.inicio);
      nav.pushNamed(AppRoutes.lots);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _visit.activeTraps.length;
    final justified = _visit.trapStates.values.where((s) => s == TrapVisitState.justificada).length;

    return Scaffold(
      appBar: const SimpleAppBar(title: 'Finalizar lote'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenH),
        children: [
          FutureBuilder<int>(
            future: _pendingSync,
            builder: (_, snap) => ValueListenableBuilder<bool>(
              valueListenable: AppServices.isOnline,
              builder: (_, online, __) => InfoTableCard(
                title: 'Resumen de la visita · ${_visit.activeLot?.name ?? ''}',
                rows: [
                  InfoRowData('Trampas registradas', value: '${_visit.registeredCount}/$total'),
                  if (justified > 0) InfoRowData('Trampas con observación', value: '$justified'),
                  InfoRowData('Lecturas guardadas', value: '${_visit.registeredCount}'),
                  InfoRowData('Pendientes de sincronización', value: snap.hasData ? '${snap.data}' : (snap.hasError ? 'No disponible' : '…')),
                  InfoRowData('Conexión', trailing: ConnectionChip(isOnline: online)),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_visit.canFinishLot)
            const AlertBanner(
              type: AlertType.info,
              title: 'Puedes finalizar el lote',
              message: 'Los datos permanecerán guardados hasta que exista conexión.',
            )
          else
            AlertBanner(
              title: 'Aún no puedes finalizar el lote',
              message: 'Faltan ${_visit.pendingCount} trampa(s) por registrar o justificar.',
            ),
        ],
      ),
      bottomNavigationBar: BottomActions(children: [
        PrimaryButton(
          label: 'Finalizar lote',
          loadingLabel: 'Finalizando...',
          isLoading: _busy,
          color: AppColors.primaryDark,
          onPressed: _visit.canFinishLot ? _finish : null,
        ),
      ]),
    );
  }
}
