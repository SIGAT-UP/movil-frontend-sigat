import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../app/shell_nav.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/trap.dart';
import '../../shared/shared.dart';
import '../visit/visit_controller.dart';

/// M12c-T — Trampa identificada, con sus validaciones.
class TrapIdentifiedScreen extends StatelessWidget {
  const TrapIdentifiedScreen({super.key, required this.lookup});
  final TrapLookup lookup;

  @override
  Widget build(BuildContext context) {
    final trap = lookup.trap;
    final visit = VisitController.instance;
    final lotName = visit.activeLot?.name ?? 'lote';
    final alreadyRegistered = visit.trapStates[trap.id] == TrapVisitState.registrada;
    final next = visit.nextTrap;

    // Reglas del recorrido: solo se registra la trampa que sigue, y solo del lote activo.
    final String? blockReason = !lookup.belongsToActiveLot
        ? 'Esta trampa no pertenece al $lotName. Revisa el código o el lote en curso.'
        : (!alreadyRegistered && next != null && next.id != trap.id)
            ? 'El recorrido va en orden. Primero registra ${next.label}.'
            : (!alreadyRegistered && visit.stateOf(trap) == TrapVisitState.justificada)
                ? 'Esta trampa ya quedó como no registrada con observación.'
                : null;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SimpleAppBar(title: 'Trampa identificada'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenH),
        children: [
          TrapHeaderCard(code: trap.icaCode, subtitle: '${trap.label} · ${trap.type}', badge: 'Identificada', large: true),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Validación',
                    style: AppText.overline),
                const SizedBox(height: 8),
                ValidationRow(
                  ok: lookup.belongsToActiveLot,
                  label: lookup.belongsToActiveLot ? 'Pertenece al $lotName' : 'No pertenece al $lotName',
                ),
                ValidationRow(
                  ok: lookup.insideLot,
                  label: 'Ubicación del dispositivo dentro del lote',
                  pendingHint: 'Se verifica con el GPS del mapa',
                ),
                ValidationRow(ok: lookup.inCatalog, label: 'Código ICA en el catálogo'),
                const Divider(height: 24, color: AppColors.border),
                Row(
                  children: [
                    const Text('Última lectura', style: AppText.secondary),
                    const Spacer(),
                    Text(
                      trap.lastReadingDate == null
                          ? 'Sin lecturas'
                          : '${trap.lastCaptures ?? 0} capturas · ${Fmt.date(trap.lastReadingDate!)}',
                      style: AppText.bodySmStrong.copyWith(color: AppColors.primaryDark),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Celda de la retícula: ${trap.gridCell ?? '-'} · coordenadas WGS84 '
                  '${trap.lat.toStringAsFixed(5)}, ${trap.lng.toStringAsFixed(5)}',
                  style: AppText.micro,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AlertBanner(
            type: AlertType.warning,
            title: lookup.allValid ? 'Si la configuración no coincide' : 'Revisa la validación',
            message: 'Verás un aviso y podrás continuar o revisar. No se bloquea el registro.',
          ),
          if (blockReason != null) ...[
            const SizedBox(height: AppSpacing.md),
            AlertBanner(title: 'No puedes registrar esta trampa', message: blockReason),
          ],
          if (alreadyRegistered) ...[
            const SizedBox(height: AppSpacing.md),
            const AlertBanner(
              type: AlertType.success,
              title: 'Esta trampa ya tiene lectura en esta visita',
              message: 'Si registras de nuevo, se reemplaza la lectura anterior.',
            ),
          ],
        ],
      ),
      bottomNavigationBar: BottomActions(children: [
        PrimaryButton(
          label: alreadyRegistered ? 'Actualizar lectura' : 'Registrar lectura',
          color: AppColors.primaryDark,
          onPressed: blockReason != null
              ? null
              : () => Navigator.of(context).pushReplacementNamed(AppRoutes.registerReading, arguments: trap),
        ),
        SecondaryButton(
          label: blockReason != null && next != null && lookup.belongsToActiveLot
              ? 'Ir a ${next.label} en el mapa'
              : 'Ver en el mapa',
          onPressed: () {
            visit.focusTrap(blockReason != null && next != null && lookup.belongsToActiveLot ? next : trap);
            ShellNav.goTo(context, AppTab.mapa);
          },
        ),
      ]),
    );
  }
}
