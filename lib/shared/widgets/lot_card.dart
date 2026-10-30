import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';
import '../../data/models/lot.dart';

StatusTone lotTone(LotStatus s) => switch (s) {
      LotStatus.pendiente => StatusTone.warning,
      LotStatus.enCurso => StatusTone.info,
      LotStatus.visitado => StatusTone.success,
    };

/// Tarjeta seleccionable de lote (S02 Lotes asignados).
class LotCard extends StatelessWidget {
  const LotCard({super.key, required this.lot, required this.selected, required this.onTap});

  final Lot lot;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      borderColor: selected ? AppColors.primary : AppColors.border,
      color: selected ? AppColors.selectedTint : AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(lot.code,
                  style: AppText.overline),
              const SizedBox(width: 8),
              Icon(
                selected ? Icons.check_circle : Icons.circle,
                size: 20,
                color: selected ? AppColors.primary : AppColors.selectorIdle,
              ),
              const SizedBox(width: 4),
              Text(selected ? 'Seleccionado' : 'Seleccionar',
                  style: AppText.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: selected ? AppColors.primaryDark : AppColors.textSecondary)),
              const Spacer(),
              StatusBadge(lot.status.label, tone: lotTone(lot.status), icon: Icons.schedule),
            ],
          ),
          const SizedBox(height: 10),
          Text(lot.name, style: AppText.h2),
          const SizedBox(height: 2),
          Text('Productor: ${lot.producer}', style: AppText.secondary),
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.location_on, size: 13, color: AppColors.info),
              const SizedBox(width: 2),
              Text(lot.municipality, style: AppText.bodySm),
            ],
          ),
          const Divider(height: 20, color: AppColors.border),
          Text(
            lot.lastInspection == null ? 'Sin inspecciones' : 'Última inspección: ${Fmt.date(lot.lastInspection!)}',
            style: AppText.caption,
          ),
        ],
      ),
    );
  }
}
