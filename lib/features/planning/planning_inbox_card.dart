import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/widgets/widgets.dart';
import 'planning_inbox_controller.dart';

/// Acceso a "Planificaciones" para el inicio del técnico y del productor.
///
/// Carga el buzón una sola vez al montarse y muestra cuántas están pendientes
/// de respuesta. Misma tarjeta para los dos roles; solo cambia el texto.
class PlanningInboxCard extends StatefulWidget {
  const PlanningInboxCard({super.key, required this.subtitle});

  final String subtitle;

  @override
  State<PlanningInboxCard> createState() => _PlanningInboxCardState();
}

class _PlanningInboxCardState extends State<PlanningInboxCard> {
  final _ctrl = PlanningInboxController.instance;

  @override
  void initState() {
    super.initState();
    if (_ctrl.items.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ctrl.load());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _ctrl,
      builder: (context, _) {
        final pendientes = _ctrl.pendingCount;
        return AppCard(
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.planningList),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.event_note_outlined,
                    size: AppIconSize.md, color: AppColors.primaryDark),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Planificaciones', style: AppText.title),
                        if (pendientes > 0) ...[
                          const SizedBox(width: AppSpacing.sm),
                          StatusBadge(
                            pendientes == 1 ? 'Nueva' : '$pendientes nuevas',
                            tone: StatusTone.warning,
                          ),
                        ],
                      ],
                    ),
                    Text(
                      pendientes > 0
                          ? 'Tienes $pendientes sin responder'
                          : widget.subtitle,
                      style: AppText.secondary,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        );
      },
    );
  }
}
