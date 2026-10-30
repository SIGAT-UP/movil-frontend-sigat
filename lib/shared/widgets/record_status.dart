import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';

/// Estado de un registro respecto al servidor.
/// Un solo lugar define su texto, color e ícono para todo el sistema.
enum RecordStatus {
  pendiente('Pendiente', StatusTone.warning, Icons.schedule),
  local('Guardado localmente', StatusTone.warning, Icons.phone_android),
  enviando('Enviando...', StatusTone.info, Icons.sync),
  enviado('Enviado', StatusTone.success, Icons.check),
  sincronizado('Sincronizado', StatusTone.success, Icons.check),
  confirmado('Confirmado', StatusTone.success, Icons.verified_outlined),
  enRevision('En revisión', StatusTone.info, Icons.rate_review_outlined);

  const RecordStatus(this.label, this.tone, this.icon);
  final String label;
  final StatusTone tone;
  final IconData icon;

  bool get isDone => this == enviado || this == sincronizado || this == confirmado;
}

/// Badge de estado de registro. `label` permite un texto más largo
/// (ej. "Pendiente de sincronizar") sin cambiar color ni ícono.
class RecordStatusBadge extends StatelessWidget {
  const RecordStatusBadge(this.status, {super.key, this.label});
  final RecordStatus status;
  final String? label;

  @override
  Widget build(BuildContext context) => StatusBadge(label ?? status.label, tone: status.tone, icon: status.icon);
}
