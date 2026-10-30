import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/planning.dart';
import '../../shared/shared.dart';
import 'planning_inbox_controller.dart';

/// Planificaciones recibidas. La usan el Técnico ("Asignaciones") y el
/// Productor ("Planificaciones"): solo cambian los textos del encabezado.
class PlanningListScreen extends StatefulWidget {
  const PlanningListScreen({super.key, this.title = 'Asignaciones', this.subtitle});

  final String title;
  final String? subtitle;

  @override
  State<PlanningListScreen> createState() => _PlanningListScreenState();
}

class _PlanningListScreenState extends State<PlanningListScreen> {
  final _ctrl = PlanningInboxController.instance;
  int _tab = 0;

  /// null = "Todas".
  static const _filtros = <PlanningStatus?>[
    PlanningStatus.pendiente,
    PlanningStatus.aceptada,
    PlanningStatus.rechazada,
    null,
  ];
  static const _etiquetas = ['Pendientes', 'Aceptadas', 'Rechazadas', 'Todas'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ctrl.load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: SimpleAppBar(title: widget.title),
      body: ListenableBuilder(
        listenable: _ctrl,
        builder: (context, _) {
          if (_ctrl.loading && _ctrl.items.isEmpty) return const AppLoader();
          if (_ctrl.error != null && _ctrl.items.isEmpty) {
            return EmptyState(
              icon: Icons.cloud_off,
              title: 'No se pudieron cargar',
              message: _ctrl.error,
              action: SecondaryButton(label: 'Reintentar', onPressed: _ctrl.load),
            );
          }

          final lista = _ctrl.filtered(_filtros[_tab]);
          return ResponsiveBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenH, AppSpacing.md, AppSpacing.screenH, AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.subtitle != null) ...[
                        Text(widget.subtitle!, style: AppText.secondary),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      PillTabs(
                        labels: _etiquetas,
                        selected: _tab,
                        onChanged: (i) => setState(() => _tab = i),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: lista.isEmpty
                      ? EmptyState(
                          icon: Icons.event_available_outlined,
                          title: 'Nada por aquí',
                          message: _tab == 3
                              ? 'Todavía no has recibido planificaciones.'
                              : 'No tienes planificaciones ${_etiquetas[_tab].toLowerCase()}.',
                        )
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: _ctrl.load,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(
                                AppSpacing.screenH, AppSpacing.sm, AppSpacing.screenH, AppSpacing.xl),
                            itemCount: lista.length,
                            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                            itemBuilder: (_, i) => PlanningCard(
                              planning: lista[i],
                              onTap: () => Navigator.of(context)
                                  .pushNamed(AppRoutes.planningDetail, arguments: lista[i].id),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
