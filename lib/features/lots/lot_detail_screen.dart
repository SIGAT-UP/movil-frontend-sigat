import 'package:flutter/material.dart';

import '../../app/shell_nav.dart';
import '../../core/widgets/widgets.dart';
import '../../data/app_services.dart';
import '../../data/models/lot.dart';
import '../visit/visit_controller.dart';

/// M02-T — Detalle del lote. "Iniciar inspección" abre el mapa.
class LotDetailScreen extends StatefulWidget {
  const LotDetailScreen({super.key, required this.lotId});
  final String lotId;

  @override
  State<LotDetailScreen> createState() => _LotDetailScreenState();
}

class _LotDetailScreenState extends State<LotDetailScreen> {
  late Future<Lot> _future = AppServices.lots.getLot(widget.lotId);
  bool _starting = false;

  Future<void> _start(Lot lot) async {
    final visit = VisitController.instance;
    final current = visit.activeLot;
    if (current != null && current.id != lot.id && visit.handledCount > 0) {
      final ok = await showAppConfirmDialog(
        context,
        title: 'Hay un lote en curso',
        message: 'Tienes ${current.name} sin finalizar. ¿Quieres cambiar a ${lot.name}? '
            'Las lecturas ya guardadas se conservan.',
        confirmLabel: 'Cambiar',
      );
      if (!ok || !mounted) return;
    }
    setState(() => _starting = true);
    try {
      await visit.startLot(lot);
      // El mapa valida si el mosaico está descargado y muestra la advertencia si no.
      if (mounted) ShellNav.goTo(context, AppTab.mapa);
    } catch (e) {
      if (mounted) {
        AppMessenger.error('No se pudo iniciar la inspección', message: 'Intenta de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Lot>(
      future: _future,
      builder: (context, snap) {
        final lot = snap.data;
        return Scaffold(
          appBar: SimpleAppBar(title: lot == null ? 'Detalle del lote' : '${lot.name} · ${lot.crop}'),
          body: switch (snap.connectionState) {
            ConnectionState.done when snap.hasError => EmptyState(
                icon: Icons.error_outline,
                title: 'No se pudo cargar el lote',
                message: '${snap.error}',
                action: SecondaryButton(
                  label: 'Reintentar',
                  onPressed: () => setState(() => _future = AppServices.lots.getLot(widget.lotId)),
                ),
              ),
            ConnectionState.done => _content(lot!),
            _ => const AppLoader(),
          },
          bottomNavigationBar: lot == null
              ? null
              : BottomActions(children: [
                  PrimaryButton(
                    label: lot.status == LotStatus.visitado ? 'Lote finalizado' : 'Iniciar inspección',
                    loadingLabel: 'Preparando...',
                    isLoading: _starting,
                    color: AppColors.primaryDark,
                    onPressed: lot.status == LotStatus.visitado ? null : () => _start(lot),
                  ),
                ]),
        );
      },
    );
  }

  Widget _content(Lot lot) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenH),
      children: [
        InfoTableCard(rows: [
          InfoRowData('Propietario', value: lot.owner),
          InfoRowData('Cultivo', value: lot.crop),
          InfoRowData('Área', value: '${lot.areaHa.toStringAsFixed(1).replaceAll('.', ',')} ha'),
          InfoRowData('Estado de vigilancia',
              trailing: lot.vigilanceActive
                  ? const StatusBadge('Activa', icon: Icons.check)
                  : const StatusBadge('Inactiva', tone: StatusTone.neutral)),
          InfoRowData('Número de trampas', value: '${lot.trapCount}'),
          InfoRowData('Última visita', value: lot.lastVisit == null ? 'Sin visitas' : Fmt.date(lot.lastVisit!)),
        ]),
        if (lot.control != null) ...[
          const SizedBox(height: AppSpacing.lg),
          InfoTableCard(
            title: 'Control vigente',
            highlighted: true,
            showDividers: false,
            footer: lot.control!.note,
            rows: [
              InfoRowData('MTD estimado', value: '${lot.control!.mtd.toStringAsFixed(2).replaceAll('.', ',')} mosc./trampa/día'),
              InfoRowData('Umbral exportación', value: lot.control!.exportThreshold),
              InfoRowData('Concepto de aptitud', value: lot.control!.aptitude),
            ],
          ),
        ],
        if (lot.program != null) ...[
          const SizedBox(height: AppSpacing.lg),
          const Center(
            child: Text('Programa de inspección vigente',
                style: AppText.title),
          ),
          InfoTableCard(
            showDividers: false,
            rows: [
              InfoRowData('Periodo de lectura', value: lot.program!.readingPeriod),
              InfoRowData('Buenas prácticas',
                  trailing: Text(lot.program!.goodPractices,
                      style: AppText.bodySmStrong.copyWith(color: AppColors.primary))),
              InfoRowData('Escenario de trampeo', value: lot.program!.scenario),
            ],
          ),
        ],
      ],
    );
  }
}
