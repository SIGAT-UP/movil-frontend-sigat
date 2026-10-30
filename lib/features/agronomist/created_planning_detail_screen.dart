import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/planning.dart';
import '../../data/pdf_service.dart';
import '../../shared/shared.dart';
import 'agronomist_controller.dart';

/// Detalle de una planificación CREADA por el Agrónomo.
///
/// Es de consulta: el Agrónomo no acepta ni rechaza lo que él mismo creó.
/// Arriba se ve cómo va; si fue rechazada, el aviso rojo y el motivo que
/// escribió el destinatario, y abajo el botón para crear una nueva con los
/// mismos datos.
class CreatedPlanningDetailScreen extends StatefulWidget {
  const CreatedPlanningDetailScreen({super.key, required this.planningId});
  final String planningId;

  @override
  State<CreatedPlanningDetailScreen> createState() => _CreatedPlanningDetailScreenState();
}

class _CreatedPlanningDetailScreenState extends State<CreatedPlanningDetailScreen> {
  final _ctrl = AgronomistController.instance;
  bool _downloading = false;

  Future<void> _download(Planning p) async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      await PdfService.instance.downloadInstructions(p);
    } catch (_) {
      if (mounted) AppMessenger.error('No se pudo preparar el documento', message: 'Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SimpleAppBar(title: 'Detalle de planificación'),
      body: ListenableBuilder(
        listenable: _ctrl,
        builder: (context, _) {
          final p = _ctrl.planningById(widget.planningId);
          if (p == null) {
            return const EmptyState(
              icon: Icons.help_outline,
              title: 'Planificación no encontrada',
              message: 'Vuelve a la lista y ábrela de nuevo.',
            );
          }
          final esTecnico = p.target == PlanningTarget.tecnico;
          final rol = esTecnico ? 'técnico' : 'productor';
          return ResponsiveBody(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screenH),
              children: [
                // --- Cómo va ---
                _EstadoBanner(planning: p, rol: rol),

                // --- Motivo del rechazo ---
                if (p.status == PlanningStatus.rechazada) ...[
                  const SizedBox(height: AppSpacing.lg),
                  const SectionTitle('Motivo del rechazo'),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      border: Border.all(color: AppColors.errorBorder),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.rejectionReason == null ? 'No se registró un motivo.' : '“${p.rejectionReason}”',
                          style: AppText.body.copyWith(fontStyle: FontStyle.italic, color: AppColors.error),
                        ),
                        if (p.respondedAt != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(Fmt.dateTime24(p.respondedAt!), style: AppText.caption),
                        ],
                      ],
                    ),
                  ),
                ],

                // --- Información ---
                const SizedBox(height: AppSpacing.lg),
                const SectionTitle('Información de la planificación'),
                const SizedBox(height: AppSpacing.sm),
                AppCard(
                  child: Column(
                    children: [
                      _Dato(Icons.calendar_month_outlined, 'Fecha propuesta', Fmt.weekdayDate(p.startDate)),
                      if (p.endDate != null)
                        _Dato(Icons.event_available_outlined, 'Hasta', Fmt.weekdayDate(p.endDate!)),
                      if (p.scheduleFrom != null)
                        _Dato(Icons.schedule, 'Horario',
                            p.scheduleTo == null ? p.scheduleFrom! : '${p.scheduleFrom} - ${p.scheduleTo}'),
                      _Dato(Icons.person_outline, esTecnico ? 'Técnico' : 'Productor', p.recipientName),
                      _Dato(Icons.task_alt, 'Actividad', p.activity),
                      if (p.lotNames.isNotEmpty) _Dato(Icons.eco_outlined, 'Lotes', p.lotNames.join(', ')),
                    ],
                  ),
                ),

                // --- Documento ---
                const SizedBox(height: AppSpacing.lg),
                const SectionTitle('Documento de instrucciones'),
                const SizedBox(height: AppSpacing.sm),
                DocumentCard(
                  doc: p.doc,
                  onTap: p.doc == null
                      ? null
                      : () => Navigator.of(context).pushNamed(AppRoutes.documentViewer, arguments: p),
                  onDownload: p.doc == null || !PdfService.instance.canDownloadInstructions(p) || _downloading
                      ? null
                      : () => _download(p),
                ),

                // --- Observaciones ---
                const SizedBox(height: AppSpacing.lg),
                const SectionTitle('Observaciones'),
                const SizedBox(height: AppSpacing.sm),
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(
                      p.observations?.isNotEmpty == true ? p.observations! : 'Sin observaciones.',
                      style: p.observations?.isNotEmpty == true ? AppText.body : AppText.secondary,
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Creada el ${Fmt.date(p.createdAt)} por ${p.createdByName}',
                  style: AppText.micro,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: _ctrl,
        builder: (context, _) {
          final p = _ctrl.planningById(widget.planningId);
          if (p == null || p.status != PlanningStatus.rechazada) return const SizedBox.shrink();
          return BottomActions(children: [
            PrimaryButton(
              label: 'Crear nueva planificación',
              icon: Icons.add,
              color: AppColors.primaryDark,
              // Reemplaza este detalle: al guardar la nueva se vuelve a la lista.
              onPressed: () => Navigator.of(context).pushReplacementNamed(
                AppRoutes.agroNewPlanning,
                arguments: p,
              ),
            ),
            SecondaryButton(
              label: 'Volver a mis planificaciones',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ]);
        },
      ),
    );
  }
}

/// Aviso superior según el estado, visto por quien la creó.
class _EstadoBanner extends StatelessWidget {
  const _EstadoBanner({required this.planning, required this.rol});
  final Planning planning;
  final String rol;

  @override
  Widget build(BuildContext context) {
    final p = planning;
    final nombre = p.target == PlanningTarget.tecnico ? 'Asignación' : 'Planificación';
    final (IconData icono, Color fondo, Color borde, Color color, String titulo, String texto) =
        switch (p.status) {
      PlanningStatus.rechazada => (
          Icons.close_rounded,
          AppColors.errorLight,
          AppColors.errorBorder,
          AppColors.error,
          '$nombre rechazada',
          'El $rol rechazó esta planificación.',
        ),
      PlanningStatus.pendiente => (
          Icons.hourglass_top_rounded,
          AppColors.infoLight,
          AppColors.infoBorder,
          AppColors.info,
          p.target == PlanningTarget.tecnico ? 'Asignada' : 'En revisión',
          p.target == PlanningTarget.tecnico
              ? 'Autorizada. ${p.recipientName} la completa al terminar sus visitas en los lotes.'
              : 'Esperando la respuesta de ${p.recipientName}.',
        ),
      PlanningStatus.aceptada => (
          Icons.check_rounded,
          AppColors.primaryLight,
          AppColors.successBorder,
          AppColors.primaryDark,
          '$nombre aceptada',
          p.respondedAt == null
              ? '${p.recipientName} la aceptó.'
              : '${p.recipientName} la aceptó el ${Fmt.dateTime24(p.respondedAt!)}.',
        ),
      PlanningStatus.completada => (
          Icons.verified_outlined,
          AppColors.surface,
          AppColors.border,
          AppColors.textSecondary,
          '$nombre completada',
          'La actividad ya se realizó.',
        ),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: fondo,
        border: Border.all(color: borde),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Icon(icono, size: 40, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: AppText.h3.copyWith(color: color)),
                const SizedBox(height: 2),
                Text(texto, style: AppText.bodySm.copyWith(color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila de dato con ícono, etiqueta y valor alineados.
class _Dato extends StatelessWidget {
  const _Dato(this.icono, this.etiqueta, this.valor);
  final IconData icono;
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, size: AppIconSize.md, color: AppColors.primaryDark),
            const SizedBox(width: AppSpacing.md),
            SizedBox(width: 120, child: Text(etiqueta, style: AppText.secondary)),
            Expanded(child: Text(valor, style: AppText.bodySmStrong, textAlign: TextAlign.right)),
          ],
        ),
      );
}
