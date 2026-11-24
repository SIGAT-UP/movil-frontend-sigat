import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';
import '../../data/app_services.dart';
import '../../data/models/visit.dart';
import '../../shared/shared.dart';

/// Detalle de una visita del historial: datos generales, lotes inspeccionados y estado de
/// revisión. Sin conexión muestra la última copia guardada, con aviso y fecha.
class VisitDetailScreen extends StatefulWidget {
  const VisitDetailScreen({super.key, required this.visitId});
  final String visitId;

  @override
  State<VisitDetailScreen> createState() => _VisitDetailScreenState();
}

class _VisitDetailScreenState extends State<VisitDetailScreen> {
  late Future<VisitRecord> _future =
      AppServices.history.getVisit(widget.visitId);

  void _reintentar() =>
      setState(() => _future = AppServices.history.getVisit(widget.visitId));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<VisitRecord>(
      future: _future,
      builder: (context, snap) {
        final v = snap.data;
        return Scaffold(
          appBar: SimpleAppBar(
              title: v == null ? 'Detalle de visita' : Fmt.date(v.date)),
          body: switch (snap.connectionState) {
            ConnectionState.done when snap.hasError => ErrorState(
                error: snap.error,
                what: 'el detalle de la visita',
                onRetry: _reintentar),
            ConnectionState.done => _contenido(v!),
            _ => const AppLoader(),
          },
        );
      },
    );
  }

  Widget _contenido(VisitRecord v) => ResponsiveBody(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenH),
          children: [
            if (v.cachedAt != null) ...[
              AlertBanner(
                type: AlertType.warning,
                title: 'Sin conexión',
                message:
                    'Mostrando la copia guardada el ${Fmt.date(v.cachedAt!)}.',
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // --- Datos generales ---
            InfoTableCard(rows: [
              InfoRowData('Fecha', value: Fmt.date(v.date)),
              InfoRowData('Predio', value: v.predioNombre ?? 'Sin dato'),
              InfoRowData('Técnico', value: v.tecnico ?? 'Sin dato'),
              InfoRowData('Lotes', value: '${v.lotsDone}/${v.lotsTotal}'),
              if (v.trampasLeidas != null)
                InfoRowData('Trampas leídas', value: '${v.trampasLeidas}'),
              InfoRowData(
                'Estado de la visita',
                trailing: StatusBadge(v.status.label, tone: _tone(v.status)),
              ),
            ]),
            const SizedBox(height: AppSpacing.lg),

            // --- Revisión ---
            const SectionTitle('Revisión del agrónomo'),
            const SizedBox(height: AppSpacing.sm),
            InfoTableCard(rows: [
              InfoRowData(
                'Estado',
                trailing: StatusBadge(
                  _textoRevision(v.estadoRevision),
                  tone: _toneRevision(v.estadoRevision),
                ),
              ),
              if (v.motivoRevision != null)
                InfoRowData('Motivo', value: v.motivoRevision),
            ]),
            const SizedBox(height: AppSpacing.lg),

            // --- Lotes ---
            const SectionTitle('Lotes inspeccionados'),
            const SizedBox(height: AppSpacing.sm),
            if (v.lotes.isEmpty)
              const Text('Sin lotes registrados', style: AppText.caption)
            else
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final lote in v.lotes)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(lote, style: AppText.title),
                      ),
                  ],
                ),
              ),
          ],
        ),
      );

  StatusTone _tone(VisitStatus s) => switch (s) {
        VisitStatus.enProgreso => StatusTone.warning,
        VisitStatus.completada => StatusTone.info,
        VisitStatus.sincronizada => StatusTone.success,
      };

  static String _textoRevision(String? estado) => switch (estado) {
        null => 'Aún no enviada',
        'pendiente' => 'Pendiente de revisión',
        'aceptado' => 'Aceptada',
        _ => estado,
      };

  static StatusTone _toneRevision(String? estado) => switch (estado) {
        'aceptado' => StatusTone.success,
        'pendiente' => StatusTone.warning,
        _ => StatusTone.neutral,
      };
}
