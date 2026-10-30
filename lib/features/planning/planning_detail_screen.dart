import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/planning.dart';
import '../../data/pdf_service.dart';
import '../../shared/shared.dart';
import 'planning_inbox_controller.dart';

/// Detalle de una planificación recibida. El PRODUCTOR la acepta o rechaza; la actividad del
/// TÉCNICO ya viene autorizada (regla de la BD) y solo muestra su avance por lote.
/// Lee del controlador por id, así que el estado siempre está al día.
class PlanningDetailScreen extends StatefulWidget {
  const PlanningDetailScreen({super.key, required this.planningId});
  final String planningId;

  @override
  State<PlanningDetailScreen> createState() => _PlanningDetailScreenState();
}

class _PlanningDetailScreenState extends State<PlanningDetailScreen> {
  bool _downloading = false;

  Future<void> _download(Planning p) async {
    if (_downloading) return;
    _downloading = true;
    try {
      await PdfService.instance.downloadInstructions(p);
    } catch (_) {
      if (mounted) AppMessenger.error('No se pudo preparar el documento', message: 'Intenta de nuevo.');
    } finally {
      _downloading = false;
    }
  }

  final _ctrl = PlanningInboxController.instance;

  Future<void> _accept(Planning p) async {
    final ok = await showAppConfirmDialog(
      context,
      title: 'Aceptar planificación',
      message: '¿Confirmas que aceptas "${p.activity}" para el ${Fmt.date(p.startDate)}?',
      confirmLabel: 'Aceptar',
    );
    if (!ok || !mounted) return;
    final hecho = await _ctrl.accept(p.id);
    if (!mounted) return;
    if (hecho) {
      AppMessenger.success('Planificación aceptada', message: 'Ya aparece como aceptada en tu lista.');
    } else {
      AppMessenger.error('No se pudo aceptar', message: _ctrl.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SimpleAppBar(title: 'Detalles de asignación'),
      body: ListenableBuilder(
        listenable: _ctrl,
        builder: (context, _) {
          final p = _ctrl.byId(widget.planningId);
          if (p == null) {
            return EmptyState(
              icon: Icons.help_outline,
              title: 'Planificación no encontrada',
              message: 'Es posible que ya no esté disponible.',
              action: SecondaryButton(label: 'Volver', onPressed: () => Navigator.of(context).pop()),
            );
          }

          return ResponsiveBody(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screenH),
              children: [
                // --- Actividad + estado ---
                AppCard(
                  tone: AppCardTone.highlighted,
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(color: AppColors.primaryDark, shape: BoxShape.circle),
                        child: const Icon(Icons.eco_outlined, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.activity, style: AppText.h3),
                            const SizedBox(height: 4),
                            PlanningStatusBadge(p.status),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // --- Datos ---
                InfoTableCard(rows: [
                  InfoRowData('Fecha', value: Fmt.date(p.startDate)),
                  if (p.endDate != null) InfoRowData('Finaliza', value: Fmt.date(p.endDate!)),
                  if (p.durationDays != null) InfoRowData('Duración', value: '${p.durationDays} días'),
                  if (p.scheduleFrom != null)
                    InfoRowData('Horario', value: '${p.scheduleFrom} – ${p.scheduleTo ?? ''}'),
                  if (p.lotNames.isNotEmpty) InfoRowData('Lotes', value: p.lotNames.join(', ')),
                  if (p.target == PlanningTarget.tecnico)
                    for (final n in p.lotNames) InfoRowData(n, value: p.resultOf(n).label),
                  InfoRowData('Enviada por', value: p.createdByName),
                  if (p.respondedAt != null)
                    InfoRowData('Respondida', value: Fmt.date(p.respondedAt!)),
                ]),

                // --- Motivo del rechazo, si aplica ---
                if (p.status == PlanningStatus.rechazada && p.rejectionReason != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  AlertBanner(
                    title: 'Rechazaste esta planificación',
                    message: p.rejectionReason,
                  ),
                ],

                // --- Documento ---
                const SizedBox(height: AppSpacing.lg),
                const SectionTitle('Documento de instrucciones'),
                const SizedBox(height: AppSpacing.sm),
                DocumentCard(
                  doc: p.doc,
                  onTap: p.doc == null
                      ? null
                      : () => Navigator.of(context)
                          .pushNamed(AppRoutes.documentViewer, arguments: p),
                  onDownload: p.doc == null || !PdfService.instance.canDownloadInstructions(p)
                      ? null
                      : () => _download(p),
                ),

                // --- Observaciones ---
                const SizedBox(height: AppSpacing.lg),
                const SectionTitle('Observaciones del agrónomo'),
                const SizedBox(height: AppSpacing.sm),
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    p.observations?.isNotEmpty == true
                        ? p.observations!
                        : 'Sin observaciones registradas.',
                    style: p.observations?.isNotEmpty == true
                        ? AppText.bodySm
                        : AppText.bodySm.copyWith(color: AppColors.textHint),
                  ),
                ),

                if (p.target == PlanningTarget.tecnico) ...[
                  const SizedBox(height: AppSpacing.lg),
                  AlertBanner(
                    type: AlertType.info,
                    title: p.status == PlanningStatus.completada
                        ? 'Actividad completada'
                        : 'Actividad autorizada',
                    message: p.status == PlanningStatus.completada
                        ? 'Todos los lotes de esta actividad tienen resultado.'
                        : 'No necesitas aceptarla. Se completa cuando termines tu visita en cada lote asignado.',
                  ),
                  for (final n in p.lotNames)
                    if (p.lotJustifications[n] != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      AlertBanner(title: '$n no se ejecutó', message: p.lotJustifications[n]),
                    ],
                ] else if (!p.status.canRespond) ...[
                  const SizedBox(height: AppSpacing.lg),
                  AlertBanner(
                    type: AlertType.info,
                    title: 'Ya respondiste esta planificación',
                    message: 'Su estado es "${p.status.label}" y no se puede cambiar desde la app.',
                  ),
                ],
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: _ctrl,
        builder: (context, _) {
          final p = _ctrl.byId(widget.planningId);
          if (p == null || !p.recipientCanRespond) return const SizedBox.shrink();
          return BottomActions(children: [
            Row(
              children: [
                Expanded(
                  child: DestructiveButton(
                    label: 'Rechazar',
                    onPressed: _ctrl.responding
                        ? null
                        : () => Navigator.of(context).pushNamed(AppRoutes.planningReject, arguments: p.id),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: PrimaryButton(
                    label: 'Aceptar',
                    isLoading: _ctrl.responding,
                    color: AppColors.primaryDark,
                    onPressed: () => _accept(p),
                  ),
                ),
              ],
            ),
          ]);
        },
      ),
    );
  }
}
