import 'package:flutter/material.dart';

import '../../app/shell_nav.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/producer.dart';
import 'activity_timeline.dart';
import 'producer_controller.dart';

/// P05-P — Historial del productor (pestaña "Historial").
class ProducerHistoryScreen extends StatefulWidget {
  const ProducerHistoryScreen({super.key});

  @override
  State<ProducerHistoryScreen> createState() => _ProducerHistoryScreenState();
}

class _ProducerHistoryScreenState extends State<ProducerHistoryScreen> {
  int _tab = 0;

  /// null = Todo.
  static const List<ActivityType?> _filters = [null, ActivityType.vigilancia, ActivityType.aplicacion, ActivityType.cosecha];

  @override
  Widget build(BuildContext context) {
    final ctrl = ProducerController.instance;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: SimpleAppBar(title: 'Historial', onBack: () => ProducerNav.tab.value = ProducerTab.inicio),
      body: ResponsiveBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.md, AppSpacing.screenH, AppSpacing.sm),
              child: PillTabs(
                labels: [for (final f in _filters) f?.label ?? 'Todo'],
                selected: _tab,
                onChanged: (i) => setState(() => _tab = i),
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: ctrl,
                builder: (context, _) {
                  if (ctrl.loading && ctrl.activity.isEmpty) return const AppLoader();
                  final type = _filters[_tab];
                  final list = type == null ? ctrl.activity : ctrl.activity.where((a) => a.type == type).toList();
                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: ctrl.load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.sm, AppSpacing.screenH, AppSpacing.xl),
                      children: [ActivityTimeline(records: list, showYear: false)],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
