import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/planning.dart';
import '../../shared/shared.dart';
import 'agronomist_controller.dart';

/// Planificaciones creadas por el Agrónomo.
///
/// Cada fila muestra solo lo que se necesita para decidir si abrirla: la
/// fecha programada y cómo va (en revisión, aceptada, rechazada, completada).
/// Las rechazadas resaltan en rojo. El detalle está en la pantalla siguiente.
///
/// `target` filtra por destinatario: productores o técnicos. null = todas.
class MyPlanningsScreen extends StatefulWidget {
  const MyPlanningsScreen({super.key, this.target, this.showBack = true});
  final PlanningTarget? target;
  final bool showBack;

  @override
  State<MyPlanningsScreen> createState() => _MyPlanningsScreenState();
}

class _MyPlanningsScreenState extends State<MyPlanningsScreen> {
  final _ctrl = AgronomistController.instance;
  int _tab = 0;
  String _query = '';

  static const _etiquetas = ['Todo', 'En revisión', 'Aceptadas', 'Rechazadas', 'Completadas'];
  static const _estados = <PlanningStatus?>[
    null,
    PlanningStatus.pendiente,
    PlanningStatus.aceptada,
    PlanningStatus.rechazada,
    PlanningStatus.completada,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ctrl.loadCreatedPlannings());
  }

  List<Planning> _visibles() {
    final q = _query.trim().toLowerCase();
    final lista = _ctrl.planningsBy(_estados[_tab]).where((p) {
      if (widget.target != null && p.target != widget.target) return false;
      if (q.isEmpty) return true;
      return Fmt.weekdayDate(p.startDate).toLowerCase().contains(q) ||
          p.recipientName.toLowerCase().contains(q) ||
          p.activity.toLowerCase().contains(q) ||
          creatorStatusLabel(p.status).toLowerCase().contains(q);
    }).toList()
      // En orden de calendario, como en una agenda.
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final titulo = widget.target == PlanningTarget.tecnico ? 'Mis asignaciones' : 'Mis planificaciones';
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: SimpleAppBar(title: titulo, showBack: widget.showBack),
      body: ListenableBuilder(
        listenable: _ctrl,
        builder: (context, _) {
          final lista = _visibles();
          return ResponsiveBody(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenH, AppSpacing.md, AppSpacing.screenH, AppSpacing.sm),
                  child: AppSearchField(
                    hint: 'Buscar planificaciones...',
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, 0, AppSpacing.screenH, AppSpacing.sm),
                  child: PillTabs(
                    labels: _etiquetas,
                    selected: _tab,
                    onChanged: (i) => setState(() => _tab = i),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _ctrl.loadCreatedPlannings,
                    child: _ctrl.loadingPlannings && _ctrl.createdPlannings.isEmpty
                        ? ListView(children: const [AppLoader(padding: EdgeInsets.all(AppSpacing.xl))])
                        : _ctrl.planningsError != null && _ctrl.createdPlannings.isEmpty
                            ? ListView(
                                padding: const EdgeInsets.all(AppSpacing.screenH),
                                children: [
                                  AlertBanner(
                                    title: _ctrl.planningsError!,
                                    message: 'Desliza hacia abajo para reintentar.',
                                  ),
                                ],
                              )
                        : lista.isEmpty
                            ? ListView(
                                children: [
                                  const SizedBox(height: AppSpacing.xl),
                                  EmptyState(
                                    icon: _query.isEmpty ? Icons.event_busy_outlined : Icons.search_off,
                                    title: _query.isEmpty ? 'Sin planificaciones' : 'Sin resultados',
                                    message: _query.isEmpty
                                        ? 'Aquí verás las que crees desde Planeación.'
                                        : 'Prueba con otra fecha, nombre o estado.',
                                  ),
                                ],
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.screenH, AppSpacing.sm, AppSpacing.screenH, AppSpacing.xl),
                                itemCount: lista.length,
                                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                                itemBuilder: (context, i) => _FilaPlanificacion(
                                  planning: lista[i],
                                  onTap: () => Navigator.of(context).pushNamed(
                                    AppRoutes.agroPlanningDetail,
                                    arguments: lista[i].id,
                                  ),
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

/// Fila de la lista: calendario, fecha programada y estado.
class _FilaPlanificacion extends StatelessWidget {
  const _FilaPlanificacion({required this.planning, required this.onTap});
  final Planning planning;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rechazada = planning.status == PlanningStatus.rechazada;
    return Semantics(
      button: true,
      label: '${Fmt.weekdayDate(planning.startDate)}, ${creatorStatusLabel(planning.status)}',
      child: AppCard(
        onTap: onTap,
        color: rechazada ? AppColors.errorLight : null,
        borderColor: rechazada ? AppColors.errorBorder : AppColors.border,
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.sm, AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: rechazada ? AppColors.background : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(
                Icons.calendar_month,
                size: AppIconSize.lg,
                color: rechazada ? AppColors.error : AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Fmt.weekdayDate(planning.startDate),
                    style: AppText.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  PlanningStatusBadge.forCreator(planning.status),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textPrimary),
          ],
        ),
      ),
    );
  }
}
