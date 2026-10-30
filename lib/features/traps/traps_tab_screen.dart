import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../app/shell_nav.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/trap.dart';
import '../visit/visit_controller.dart';
import '../../shared/shared.dart';
import 'trap_flow.dart';

/// Pestaña "Trampas": lista de trampas del lote activo (vista "Lista" del mapa).
class TrapsTabScreen extends StatelessWidget {
  const TrapsTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final visit = VisitController.instance;
    return Scaffold(
      appBar: const SimpleAppBar(title: 'Trampas', showBack: false),
      body: ListenableBuilder(
        listenable: visit,
        builder: (context, _) {
          final lot = visit.activeLot;
          if (lot == null) {
            return EmptyState(
              icon: Icons.science_outlined,
              title: 'Sin lote activo',
              message: 'Inicia la inspección de un lote para ver sus trampas.',
              action: SecondaryButton(
                label: 'Ver lotes asignados',
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.lots),
              ),
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.screenH),
                  children: [
                    ProgressHeader(
                      label: '${lot.name} · ${visit.activeTraps.length} trampas',
                      trailing: '${visit.handledCount} de ${visit.activeTraps.length}',
                      value: visit.activeTraps.isEmpty ? 0 : visit.handledCount / visit.activeTraps.length,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    for (final t in visit.activeTraps) ...[
                      TrapStatusTile(
                        trap: t,
                        state: visit.stateOf(t),
                        reason: visit.skipReasons[t.id],
                        locked: visit.isLocked(t),
                        isNext: visit.nextTrap?.id == t.id,
                        onTap: switch (visit.stateOf(t)) {
                          // Siguiente del recorrido → ubicarla en el mapa.
                          TrapVisitState.pendiente when visit.nextTrap?.id == t.id => () {
                              visit.focusTrap(t);
                              ShellNav.tab.value = AppTab.mapa;
                            },
                          // Ya registrada → se puede revisar / actualizar.
                          TrapVisitState.registrada => () {
                              lookupTrap(t.icaCode).then((lookup) {
                                if (lookup != null && context.mounted) openTrapIdentified(context, lookup);
                              });
                            },
                          _ => null,
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
              BottomActions(children: [
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: 'Escanear',
                        icon: Icons.qr_code_scanner,
                        color: AppColors.primaryDark,
                        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.scanTrap),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SecondaryButton(
                        label: 'Código ICA',
                        icon: Icons.tag,
                        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.identifyTrap),
                      ),
                    ),
                  ],
                ),
              ]),
            ],
          );
        },
      ),
    );
  }
}
