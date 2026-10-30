import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';
import '../../data/models/producer.dart';
import '../producer/activity_timeline.dart';
import 'agronomist_controller.dart';
import '../../shared/shared.dart';

/// Historial del lote: inspecciones, aplicaciones y correcciones.
/// Reutiliza la línea de tiempo del productor.
class LotHistoryScreen extends StatefulWidget {
  const LotHistoryScreen({super.key, this.showBack = true});

  /// false cuando se usa como pestaña "Historial".
  final bool showBack;

  @override
  State<LotHistoryScreen> createState() => _LotHistoryScreenState();
}

class _LotHistoryScreenState extends State<LotHistoryScreen> {
  final _ctrl = AgronomistController.instance;
  int _tab = 0;

  static const _filtros = <ActivityType?>[null, ActivityType.vigilancia, ActivityType.aplicacion];
  static const _etiquetas = ['Todo', 'Inspección', 'Aplicación'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ctrl.loadHistory());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: SimpleAppBar(title: 'Historial del lote', showBack: widget.showBack),
      body: ListenableBuilder(
        listenable: _ctrl,
        builder: (context, _) {
          if (_ctrl.history.isEmpty && _ctrl.historyError != null) {
            return ErrorState(error: _ctrl.historyError, what: 'el historial del lote', onRetry: _ctrl.loadHistory);
          }
          final tipo = _filtros[_tab];
          final lista =
              tipo == null ? _ctrl.history : _ctrl.history.where((a) => a.type == tipo).toList();
          return ResponsiveBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenH, AppSpacing.md, AppSpacing.screenH, AppSpacing.sm),
                  child: PillTabs(
                    labels: _etiquetas,
                    selected: _tab,
                    onChanged: (i) => setState(() => _tab = i),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _ctrl.loadHistory,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screenH, AppSpacing.sm, AppSpacing.screenH, AppSpacing.xl),
                      children: [
                        if (lista.isEmpty)
                          const EmptyState(
                            icon: Icons.history,
                            title: 'Sin actividad',
                            message: 'Este lote todavía no tiene registros en el servidor.',
                          )
                        else
                          ActivityTimeline(records: lista, showYear: false),
                      ],
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
