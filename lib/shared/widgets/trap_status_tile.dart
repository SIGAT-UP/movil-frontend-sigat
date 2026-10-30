import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';
import '../../data/models/trap.dart';

/// Fila de trampa con su estado en la visita (reutilizada en Trampas y Visita en curso).
class TrapStatusTile extends StatelessWidget {
  const TrapStatusTile({
    super.key,
    required this.trap,
    required this.state,
    this.reason,
    this.onTap,
    this.locked = false,
    this.selected = false,
    this.isNext = false,
  });

  final Trap trap;
  final TrapVisitState state;
  final String? reason;
  final VoidCallback? onTap;

  /// Pendiente pero no es la siguiente del recorrido.
  final bool locked;
  final bool selected;

  /// Es la siguiente del recorrido (se marca aunque no esté seleccionada).
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      TrapVisitState.registrada =>
        ChecklistTile(title: trap.label, subtitle: 'Lectura guardada', done: true, onTap: onTap),
      TrapVisitState.justificada => ChecklistTile(
          title: trap.label,
          subtitle: 'No registrada: ${reason ?? 'con observación'}',
          done: true,
          tone: StatusTone.info,
          onTap: onTap,
        ),
      TrapVisitState.pendiente when locked => ChecklistTile(
          title: trap.label,
          subtitle: 'Bloqueada · primero completa la anterior',
          done: false,
          locked: true,
        ),
      TrapVisitState.pendiente => ChecklistTile(
          title: trap.label,
          subtitle: selected ? 'Seleccionada · siguiente del recorrido' : 'Siguiente · toca para seleccionar',
          done: false,
          selected: selected,
          onTap: onTap,
          trailing: isNext || selected
              ? const StatusBadge('Siguiente', tone: StatusTone.warning, icon: Icons.directions_walk)
              : null,
        ),
    };
  }
}
