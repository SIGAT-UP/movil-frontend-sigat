import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';
import '../../data/app_services.dart';
import '../../data/models/visit.dart';
import '../../shared/shared.dart';

/// M10-T — Historial de visitas.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<VisitRecord>> _future = AppServices.history.getVisits();
  int _tab = 0;

  static const _tabs = ['Todas', 'Últimos 7 días', 'Pendientes'];

  List<VisitRecord> _filter(List<VisitRecord> all) {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return switch (_tab) {
      1 => all.where((v) => v.date.isAfter(weekAgo)).toList(),
      2 => all.where((v) => v.status != VisitStatus.sincronizada).toList(),
      _ => all,
    };
  }

  StatusTone _tone(VisitStatus s) => switch (s) {
        VisitStatus.enProgreso => StatusTone.warning,
        VisitStatus.completada => StatusTone.info,
        VisitStatus.sincronizada => StatusTone.success,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SimpleAppBar(title: 'Historial de visitas'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, 12, AppSpacing.screenH, 8),
            child: PillTabs(labels: _tabs, selected: _tab, onChanged: (i) => setState(() => _tab = i)),
          ),
          Expanded(
            child: FutureBuilder<List<VisitRecord>>(
              future: _future,
              builder: (context, snap) {
                if (snap.hasError) {
                  return ErrorState(
                    error: snap.error,
                    what: 'el historial',
                    onRetry: () => setState(() => _future = AppServices.history.getVisits()),
                  );
                }
                if (!snap.hasData) {
                  return const AppLoader();
                }
                final list = _filter(snap.data!);
                if (list.isEmpty) {
                  return const EmptyState(icon: Icons.history, title: 'Sin visitas', message: 'No hay visitas con este filtro.');
                }
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    setState(() => _future = AppServices.history.getVisits());
                    await _future;
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, 4, AppSpacing.screenH, 20),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final v = list[i];
                      final showDate = i == 0 || Fmt.date(list[i - 1].date) != Fmt.date(v.date);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showDate)
                            Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 6),
                              child: Text(Fmt.relativeDay(v.date),
                                  style: AppText.caption),
                            ),
                          AppCard(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(v.title, style: AppText.title),
                                Text('${v.lotsDone}/${v.lotsTotal} lotes',
                                    style: AppText.caption),
                                const SizedBox(height: 8),
                                StatusBadge(v.status.label, tone: _tone(v.status)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
