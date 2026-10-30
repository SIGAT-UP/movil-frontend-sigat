import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';
import '../../shared/shared.dart';
import 'planning_inbox_controller.dart';

/// Rechazo de una planificación. El motivo es OBLIGATORIO: sin él, el agrónomo
/// no puede reprogramar.
class RejectPlanningScreen extends StatefulWidget {
  const RejectPlanningScreen({super.key, required this.planningId});
  final String planningId;

  @override
  State<RejectPlanningScreen> createState() => _RejectPlanningScreenState();
}

class _RejectPlanningScreenState extends State<RejectPlanningScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonCtrl = TextEditingController();
  final _ctrl = PlanningInboxController.instance;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  String? _validate(String? v) {
    final texto = v?.trim() ?? '';
    if (texto.isEmpty) return 'Escribe el motivo del rechazo. Es obligatorio.';
    if (texto.length < 10) return 'Explica un poco más: al menos 10 caracteres.';
    return null;
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_ctrl.responding) return; // evita el doble toque

    final ok = await _ctrl.reject(widget.planningId, _reasonCtrl.text.trim());
    if (!mounted) return;
    if (ok) {
      AppMessenger.success('Rechazo enviado', message: 'El agrónomo verá tu motivo.');
      Navigator.of(context).pop(); // vuelve al detalle, ya actualizado
    } else {
      // El texto NO se pierde: el formulario se conserva para reintentar.
      AppMessenger.error('No se pudo enviar el rechazo', message: _ctrl.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _ctrl.byId(widget.planningId);
    // Si hay datos sin guardar, el botón atrás pregunta antes de salir.
    return ListenableBuilder(
      listenable: Listenable.merge([_reasonCtrl]),
      builder: (context, _) => DiscardChangesGuard(
        hasChanges: _reasonCtrl.text.trim().isNotEmpty,
        message: 'El motivo que escribiste se perderá y la planificación seguirá pendiente.',
        child: Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SimpleAppBar(title: 'Rechazar asignación'),
      body: ResponsiveBody(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenH),
            children: [
              const AlertBanner(
                title: 'Al rechazar esta asignación debes poner la observación',
                message: 'El agrónomo la necesita para poder reprogramarla.',
              ),
              if (p != null) ...[
                const SizedBox(height: AppSpacing.lg),
                const SectionTitle('Resumen de asignación'),
                const SizedBox(height: AppSpacing.sm),
                InfoTableCard(rows: [
                  InfoRowData('Actividad', value: p.activity),
                  InfoRowData('Fecha', value: Fmt.date(p.startDate)),
                  if (p.lotNames.isNotEmpty) InfoRowData('Lotes', value: p.lotNames.join(', ')),
                  InfoRowData('Estado', trailing: PlanningStatusBadge(p.status)),
                ]),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Motivo del rechazo',
                controller: _reasonCtrl,
                hint: 'Explica por qué no puedes realizar esta actividad',
                maxLines: 4,
                enabled: !_ctrl.responding,
                validator: _validate,
                helper: 'Obligatorio. El agrónomo lo verá en sus planificaciones.',
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: _ctrl,
        builder: (context, _) => BottomActions(children: [
          DestructiveButton(
            label: _ctrl.responding ? 'Enviando...' : 'Enviar rechazo',
            onPressed: _ctrl.responding ? null : _send,
          ),
          SecondaryButton(
            label: 'Cancelar',
            onPressed: _ctrl.responding ? null : () => Navigator.of(context).pop(),
          ),
        ]),
      ),
        ),
      ),
    );
  }
}
