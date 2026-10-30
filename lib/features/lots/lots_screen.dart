import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/widgets/widgets.dart';
import '../../data/app_services.dart';
import '../../data/models/lot.dart';
import '../visit/visit_controller.dart';
import '../../shared/shared.dart';

/// Filtro con el que se abre la lista (p. ej. «Pendiente de visita» del inicio → pendientes).
enum LotsFilter { todos, pendientes, enCurso, visitados }

/// S02 — Lotes asignados.
class LotsScreen extends StatefulWidget {
  const LotsScreen({super.key, this.initialFilter = LotsFilter.todos});

  final LotsFilter initialFilter;

  @override
  State<LotsScreen> createState() => _LotsScreenState();
}

class _LotsScreenState extends State<LotsScreen> {
  final _visit = VisitController.instance;
  late int _tab = widget.initialFilter.index;
  String _query = '';
  String? _selectedId;

  static const _tabs = ['Todos', 'Pendientes', 'En curso', 'Visitado'];

  @override
  void initState() {
    super.initState();
    // Se carga después del primer frame: avisar a otros widgets durante el build no está permitido.
    WidgetsBinding.instance.addPostFrameCallback((_) => _visit.loadLots());
  }

  List<Lot> _filtered(List<Lot> all) {
    final q = _query.trim().toLowerCase();
    return all.where((l) {
      final byTab = switch (_tab) {
        1 => l.status == LotStatus.pendiente,
        2 => l.status == LotStatus.enCurso,
        3 => l.status == LotStatus.visitado,
        _ => true,
      };
      final byText = q.isEmpty ||
          l.name.toLowerCase().contains(q) ||
          l.code.toLowerCase().contains(q) ||
          l.producer.toLowerCase().contains(q);
      return byTab && byText;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final session = AppServices.session.value;
    return Scaffold(
      appBar: const SimpleAppBar(title: 'Lotes asignados'),
      body: ListenableBuilder(
        listenable: _visit,
        builder: (context, _) {
          final lots = _filtered(_visit.assignedLots);
          final selected = _visit.assignedLots.where((l) => l.id == _selectedId).firstOrNull;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, 12, AppSpacing.screenH, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('Téc. ${session?.shortName ?? ''}',
                              style: AppText.secondary),
                        ),
                        ValueListenableBuilder<bool>(
                          valueListenable: AppServices.isOnline,
                          builder: (_, online, __) => ConnectionChip(isOnline: online),
                        ),
                      ],
                    ),
                    if (_visit.lotsTotal > 0) ...[
                      const SizedBox(height: 10),
                      ProgressHeader(
                        label: 'Lotes finalizados',
                        trailing: '${_visit.lotsDone} de ${_visit.lotsTotal}',
                        value: _visit.lotsDone / _visit.lotsTotal,
                      ),
                    ],
                    const SizedBox(height: 12),
                    AppSearchField(hint: 'Buscar lote, productor o código', onChanged: (v) => setState(() => _query = v)),
                    const SizedBox(height: 12),
                    PillTabs(labels: _tabs, selected: _tab, onChanged: (i) => setState(() => _tab = i)),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              Expanded(child: _buildList(lots)),
              BottomActions(children: [
                PrimaryButton(
                  label: 'Ver detalles',
                  color: AppColors.primaryDark,
                  onPressed: selected == null
                      ? null
                      : () => Navigator.of(context).pushNamed(AppRoutes.lotDetail, arguments: selected.id),
                ),
              ]),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(List<Lot> lots) {
    if (_visit.loadingLots && _visit.assignedLots.isEmpty) {
      return const AppLoader();
    }
    if (_visit.lotsError != null) {
      return EmptyState(
        icon: Icons.cloud_off,
        title: 'No se pudieron cargar los lotes',
        message: _visit.lotsError,
        action: SecondaryButton(label: 'Reintentar', onPressed: _visit.loadLots),
      );
    }
    if (lots.isEmpty) {
      return const EmptyState(
        icon: Icons.location_off_outlined,
        title: 'Sin lotes',
        message: 'No hay lotes asignados con este filtro.',
      );
    }
    return RefreshIndicator(
      onRefresh: _visit.loadLots,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, 0, AppSpacing.screenH, 12),
        itemCount: lots.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => LotCard(
          lot: lots[i],
          selected: lots[i].id == _selectedId,
          onTap: () => setState(() => _selectedId = lots[i].id),
        ),
      ),
    );
  }
}
