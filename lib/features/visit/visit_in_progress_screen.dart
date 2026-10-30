import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../app/shell_nav.dart';
import '../../core/widgets/widgets.dart';
import '../../data/app_services.dart';
import '../../data/models/trap.dart';
import '../../shared/shared.dart';
import 'visit_controller.dart';

/// M07-T — Visita en curso (pestaña "Visita").
///
/// Recorrido en orden:
///  1. Solo se puede seleccionar la SIGUIENTE trampa pendiente; las demás quedan bloqueadas.
///  2. "Continuar" con la trampa seleccionada → abre el mapa para caminar hasta ella
///     y allí se escanea / ingresa el código.
///  3. Si no se pudo hacer, se escribe el motivo en "Observación" y "Continuar"
///     la marca como no registrada y pasa a la siguiente.
///  4. Con todas registradas o justificadas, "Continuar" lleva a Finalizar lote.
class VisitInProgressScreen extends StatefulWidget {
  const VisitInProgressScreen({super.key});

  @override
  State<VisitInProgressScreen> createState() => _VisitInProgressScreenState();
}

class _VisitInProgressScreenState extends State<VisitInProgressScreen> {
  final _visit = VisitController.instance;
  final _obsCtrl = TextEditingController();
  String? _selectedId;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _visit.addListener(_onVisitChanged);
  }

  @override
  void dispose() {
    _visit.removeListener(_onVisitChanged);
    _obsCtrl.dispose();
    super.dispose();
  }

  /// Si la trampa seleccionada ya no es la siguiente (se registró), se limpia la selección.
  void _onVisitChanged() {
    if (_selectedId != null && _visit.nextTrap?.id != _selectedId) {
      _selectedId = null;
      _obsCtrl.clear();
    }
  }

  Future<void> _continue() async {
    final next = _visit.nextTrap;

    // Todo hecho → finalizar lote.
    if (next == null) {
      Navigator.of(context).pushNamed(AppRoutes.finishLot);
      return;
    }

    if (_selectedId != next.id) {
      setState(() => _error = 'Selecciona ${next.label} para continuar el recorrido.');
      return;
    }

    final reason = _obsCtrl.text.trim();
    if (reason.isNotEmpty) {
      // No se pudo hacer: queda justificada y se pasa a la siguiente.
      setState(() {
        _busy = true;
        _error = null;
      });
      await _visit.justifyTrap(next, reason);
      if (!mounted) return;
      setState(() => _busy = false);
      AppMessenger.info('${next.label} quedó como no registrada', message: reason);
      return;
    }

    // Ir al mapa a buscar la trampa seleccionada.
    setState(() => _error = null);
    _visit.focusTrap(next);
    ShellNav.goTo(context, AppTab.mapa);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SimpleAppBar(title: 'Visita en curso', showBack: false, actions: [LocalStorageBadge()]),
      body: ListenableBuilder(
        listenable: _visit,
        builder: (context, _) {
          final lot = _visit.activeLot;
          if (lot == null) return _noActiveLot();
          final total = _visit.activeTraps.length;
          final next = _visit.nextTrap;
          final selectedNext = next != null && _selectedId == next.id;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.screenH),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ValueListenableBuilder<bool>(
                        valueListenable: AppServices.isOnline,
                        builder: (_, online, __) => ConnectionChip(isOnline: online),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ProgressHeader(
                      label: '${_visit.registeredCount} de $total trampas registradas del ${lot.name}',
                      value: total == 0 ? 0 : _visit.handledCount / total,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    for (final t in _visit.activeTraps) ...[
                      TrapStatusTile(
                        trap: t,
                        state: _visit.stateOf(t),
                        reason: _visit.skipReasons[t.id],
                        locked: _visit.isLocked(t),
                        selected: _selectedId == t.id,
                        isNext: next?.id == t.id,
                        onTap: t.id == next?.id
                            ? () => setState(() {
                                  _selectedId = _selectedId == t.id ? null : t.id;
                                  _error = null;
                                })
                            : null,
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (next != null) ...[
                      const SizedBox(height: 6),
                      AppTextField(
                        label: 'Observación',
                        controller: _obsCtrl,
                        hint: 'Solo si no puedes registrar ${next.label}: escribe aquí el motivo',
                        maxLines: 2,
                        enabled: selectedNext,
                        onChanged: (_) => setState(() => _error = null),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      AlertBanner(type: AlertType.warning, title: _error!),
                    ],
                  ],
                ),
              ),
              BottomActions(children: [
                PrimaryButton(
                  label: _buttonLabel(next, selectedNext),
                  loadingLabel: 'Guardando...',
                  isLoading: _busy,
                  icon: selectedNext && _obsCtrl.text.trim().isEmpty ? Icons.map_outlined : null,
                  color: AppColors.primaryDark,
                  onPressed: _continue,
                ),
              ]),
            ],
          );
        },
      ),
    );
  }

  String _buttonLabel(Trap? next, bool selectedNext) {
    if (next == null) return 'Continuar';
    if (selectedNext && _obsCtrl.text.trim().isNotEmpty) return 'Guardar motivo y continuar';
    if (selectedNext) return 'Continuar al mapa';
    return 'Continuar';
  }

  Widget _noActiveLot() {
    if (!_visit.visitInProgress) {
      return EmptyState(
        icon: Icons.fact_check_outlined,
        title: 'No hay visita en curso',
        message: 'Selecciona un lote asignado e inicia la inspección.',
        action: SecondaryButton(
          label: 'Ver lotes asignados',
          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.lots),
        ),
      );
    }
    final left = _visit.lotsTotal - _visit.lotsDone;
    return EmptyState(
      icon: Icons.fact_check_outlined,
      title: 'Lotes finalizados: ${_visit.lotsDone} de ${_visit.lotsTotal}',
      message: left > 0
          ? 'Te falta(n) $left lote(s) para poder finalizar la visita.'
          : 'Completaste todos los lotes. Ya puedes finalizar la visita.',
      action: left > 0
          ? PrimaryButton(
              label: 'Ir al siguiente lote',
              color: AppColors.primaryDark,
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.lots),
            )
          : PrimaryButton(
              label: 'Finalizar visita',
              color: AppColors.primaryDark,
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.finishVisit),
            ),
    );
  }
}
