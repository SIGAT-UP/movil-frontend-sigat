import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';
import 'record_status.dart';

/// Fila de un registro en la cola de sincronización (autorreportes del productor).
/// El fondo cambia con el estado: ámbar si sigue en el dispositivo, blanco si ya salió.
class SyncRecordTile extends StatelessWidget {
  const SyncRecordTile({
    super.key,
    required this.title,
    required this.status,
    this.date,
    this.icon = Icons.eco_outlined,
  });

  final String title;
  final RecordStatus status;
  final DateTime? date;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final pendingLike = status == RecordStatus.pendiente || status == RecordStatus.local;
    final subtitle = switch (status) {
      RecordStatus.local => 'Guardado localmente',
      RecordStatus.confirmado when date != null => '${Fmt.date(date!)} · Confirmado',
      _ when date != null => '${Fmt.date(date!)}, ${Fmt.time24(date!)}',
      _ => null,
    };

    return AppCard(
      color: pendingLike ? AppColors.warningLight : null,
      borderColor: pendingLike ? AppColors.warningBorder : null,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
      child: Row(
        children: [
          if (pendingLike) ...[
            Icon(icon, size: AppIconSize.md, color: AppColors.warningStrong),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.title),
                if (subtitle != null) Text(subtitle, style: AppText.caption),
              ],
            ),
          ),
          if (status != RecordStatus.local && status != RecordStatus.confirmado) RecordStatusBadge(status),
        ],
      ),
    );
  }
}
