import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/field_record.dart';
import 'agronomist_controller.dart';

/// Registro en revisión: lo que envió el técnico y por qué requiere revisión.
class RecordReviewScreen extends StatefulWidget {
  const RecordReviewScreen({super.key, required this.recordId});
  final String recordId;

  @override
  State<RecordReviewScreen> createState() => _RecordReviewScreenState();
}

class _RecordReviewScreenState extends State<RecordReviewScreen> {
  final _ctrl = AgronomistController.instance;

  Future<void> _accept(FieldRecord r) async {
    final ok = await showAppConfirmDialog(
      context,
      title: 'Aceptar registro',
      message: 'La visita de ${r.technicianName} quedará aceptada y saldrá de la lista de pendientes.',
      confirmLabel: 'Aceptar registro',
    );
    if (!ok || !mounted) return;
    final hecho = await _ctrl.acceptRecord(r.id);
    if (!mounted) return;
    if (hecho) {
      AppMessenger.success('Registro aceptado');
      Navigator.of(context).pop();
    } else {
      AppMessenger.error('No se pudo aceptar el registro', message: _ctrl.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SimpleAppBar(title: 'Registro en revisión'),
      body: ListenableBuilder(
        listenable: _ctrl,
        builder: (context, _) {
          final r = _ctrl.recordById(widget.recordId);
          if (r == null) {
            return EmptyState(
              icon: Icons.task_alt,
              title: 'Registro ya revisado',
              message: 'Este registro ya no está pendiente.',
              action: SecondaryButton(label: 'Volver', onPressed: () => Navigator.of(context).pop()),
            );
          }
          return ResponsiveBody(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screenH),
              children: [
                if (r.reviewReason != null)
                  AlertBanner(type: AlertType.warning, title: 'Motivo de revisión', message: r.reviewReason),
                const SizedBox(height: AppSpacing.lg),
                InfoTableCard(rows: [
                  InfoRowData('Lotes visitados', value: '${r.lotsVisited}'),
                  InfoRowData('Trampas en total', value: '${r.trapsTotal}'),
                  InfoRowData('Observación',
                      value: '${Fmt.dateNumeric(r.observedAt)} · ${Fmt.time24(r.observedAt)}'),
                  InfoRowData('Recepción',
                      value: '${Fmt.dateNumeric(r.receivedAt)} · ${Fmt.time24(r.receivedAt)}'),
                  InfoRowData('Origen', value: 'Técnico · ${r.technicianName}'),
                  InfoRowData('Estado', trailing: StatusBadge(r.status.label, tone: StatusTone.warning)),
                ]),
                const SizedBox(height: AppSpacing.lg),
                const AlertBanner(
                  type: AlertType.info,
                  title: 'La decisión es del agrónomo',
                  message: 'Puedes consultar los lotes y las lecturas antes de aceptar el registro.',
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: _ctrl,
        builder: (context, _) {
          final r = _ctrl.recordById(widget.recordId);
          if (r == null) return const SizedBox.shrink();
          return BottomActions(children: [
            SecondaryButton(
              label: 'Ver lotes',
              icon: Icons.layers_outlined,
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.agroRecordLots, arguments: r.id),
            ),
            PrimaryButton(
              label: 'Aceptar registro',
              isLoading: _ctrl.busy,
              color: AppColors.primaryDark,
              onPressed: () => _accept(r),
            ),
          ]);
        },
      ),
    );
  }
}
