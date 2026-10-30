import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';
import '../../data/models/planning.dart';

/// Traduce el estado de una planificación al tono visual del sistema.
StatusTone planningTone(PlanningStatus s) => switch (s) {
      PlanningStatus.pendiente => StatusTone.warning,
      PlanningStatus.aceptada => StatusTone.success,
      PlanningStatus.rechazada => StatusTone.error,
      PlanningStatus.completada => StatusTone.info,
    };

IconData planningIcon(PlanningStatus s) => switch (s) {
      PlanningStatus.pendiente => Icons.schedule,
      PlanningStatus.aceptada => Icons.check,
      PlanningStatus.rechazada => Icons.close,
      PlanningStatus.completada => Icons.verified_outlined,
    };

/// Distintivo de estado de una planificación.
///
/// Quien la RECIBE (técnico, productor) ve "Pendiente": le toca responder.
/// Quien la CREA (agrónomo) ve la misma planificación como "En revisión":
/// está esperando la respuesta del otro. Por eso hay dos constructores.
class PlanningStatusBadge extends StatelessWidget {
  const PlanningStatusBadge(this.status, {super.key, this.label}) : forCreator = false;
  const PlanningStatusBadge.forCreator(this.status, {super.key, this.label}) : forCreator = true;

  final PlanningStatus status;
  final String? label;
  final bool forCreator;

  @override
  Widget build(BuildContext context) => forCreator
      ? StatusBadge(label ?? creatorStatusLabel(status), tone: creatorTone(status))
      : StatusBadge(label ?? status.label, tone: planningTone(status), icon: planningIcon(status));
}

/// Estado visto por el agrónomo que creó la planificación.
String creatorStatusLabel(PlanningStatus s) => switch (s) {
      PlanningStatus.pendiente => 'En revisión',
      PlanningStatus.aceptada => 'Aceptada',
      PlanningStatus.rechazada => 'Rechazada',
      PlanningStatus.completada => 'Completada',
    };

StatusTone creatorTone(PlanningStatus s) => switch (s) {
      PlanningStatus.pendiente => StatusTone.info,
      PlanningStatus.aceptada => StatusTone.success,
      PlanningStatus.rechazada => StatusTone.error,
      PlanningStatus.completada => StatusTone.neutral,
    };

/// Tarjeta de una planificación en la lista.
/// La usan el Técnico ("Planificaciones"), el Productor y el Agrónomo
/// ("Mis planificaciones"), cambiando solo el subtítulo.
class PlanningCard extends StatelessWidget {
  const PlanningCard({super.key, required this.planning, required this.onTap, this.showRecipient = false});

  final Planning planning;
  final VoidCallback onTap;

  /// true en la vista del Agrónomo: muestra a quién va dirigida.
  final bool showRecipient;

  @override
  Widget build(BuildContext context) {
    final rechazada = planning.status == PlanningStatus.rechazada;
    return AppCard(
      onTap: onTap,
      borderColor: rechazada ? AppColors.errorBorder : AppColors.border,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: planningTone(planning.status).bg,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(
              planning.target == PlanningTarget.tecnico ? Icons.eco_outlined : Icons.event_note_outlined,
              size: 20,
              color: planningTone(planning.status).fg,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(planning.activity, style: AppText.title),
                const SizedBox(height: 2),
                Text(
                  showRecipient
                      ? '${planning.recipientName} · ${Fmt.date(planning.startDate)}'
                      : Fmt.date(planning.startDate),
                  style: AppText.caption,
                ),
                if (planning.lotNames.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(planning.lotNames.join(' · '), style: AppText.micro),
                ],
                const SizedBox(height: AppSpacing.sm),
                PlanningStatusBadge(planning.status),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textHint),
        ],
      ),
    );
  }
}

/// Tarjeta del documento de instrucciones adjunto a una planificación.
///
/// * `doc == null` → "Sin documento adjunto", no pulsable.
/// * `onTap` → abre el visor.
/// * `onDownload` → ícono de descarga a la derecha (solo si se puede descargar).
class DocumentCard extends StatelessWidget {
  const DocumentCard({super.key, this.doc, this.onTap, this.onDownload});

  final PlanningDoc? doc;
  final VoidCallback? onTap;
  final VoidCallback? onDownload;

  @override
  Widget build(BuildContext context) {
    final d = doc;
    if (d == null) {
      return const AppCard(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(Icons.description_outlined, color: AppColors.textHint),
            SizedBox(width: AppSpacing.md),
            Expanded(child: Text('Sin documento adjunto', style: AppText.secondary)),
          ],
        ),
      );
    }
    final (icono, fondo, color) = docKindStyle(d.kind);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: fondo,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icono, size: 22, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.fileName, style: AppText.title, overflow: TextOverflow.ellipsis),
                Text(d.detailLabel, style: AppText.caption),
              ],
            ),
          ),
          if (onDownload != null)
            AppIconButton(
              icon: Icons.download_outlined,
              tooltip: 'Descargar',
              color: AppColors.primaryDark,
              onPressed: onDownload,
            )
          else if (onTap != null)
            const Icon(Icons.chevron_right, color: AppColors.textHint),
        ],
      ),
    );
  }
}

/// Ícono, fondo y color de cada tipo de documento. Compartido con el visor.
(IconData, Color, Color) docKindStyle(DocKind kind) => switch (kind) {
      DocKind.pdf => (Icons.picture_as_pdf_outlined, AppColors.errorLight, AppColors.error),
      DocKind.word => (Icons.description_outlined, AppColors.infoLight, AppColors.info),
      DocKind.imagen => (Icons.image_outlined, AppColors.primaryLight, AppColors.primaryDark),
    };
