import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/field_record.dart';
import 'agronomist_controller.dart';

/// Registros de campo pendientes de aceptar (M09-T · "Ver registros").
class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key, this.showBack = true});

  /// false cuando se usa como pestaña "Revisiones".
  final bool showBack;

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  final _ctrl = AgronomistController.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ctrl.load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: SimpleAppBar(title: 'Registros', showBack: widget.showBack),
      body: ListenableBuilder(
        listenable: _ctrl,
        builder: (context, _) {
          if (_ctrl.loading && _ctrl.pendingRecords.isEmpty) return const AppLoader();
          if (_ctrl.pendingRecords.isEmpty) {
            return const EmptyState(
              icon: Icons.task_alt,
              title: 'No hay registros pendientes',
              message: 'Cuando un técnico envíe una visita para revisar, aparecerá aquí.',
            );
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _ctrl.load,
            child: ResponsiveBody(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.screenH),
                children: [
                  const SectionTitle('Registros pendientes por aceptar'),
                  const SizedBox(height: AppSpacing.md),
                  for (final r in _ctrl.pendingRecords) ...[
                    _RecordCard(
                      record: r,
                      onTap: () =>
                          Navigator.of(context).pushNamed(AppRoutes.agroRecordReview, arguments: r.id),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.record, required this.onTap});

  final FieldRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          UserAvatar(name: record.technicianName, radius: 18),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Visita Técnico ${record.technicianName.split(' ').first}', style: AppText.title),
                const SizedBox(height: 2),
                Text(
                  '${Fmt.date(record.observedAt)} · ${record.lotsVisited} lotes · ${record.trapsTotal} trampas',
                  style: AppText.caption,
                ),
                const SizedBox(height: AppSpacing.sm),
                StatusBadge(
                  record.status.label,
                  tone: record.status == RecordReviewStatus.aceptado
                      ? StatusTone.success
                      : StatusTone.warning,
                  icon: record.status == RecordReviewStatus.aceptado ? Icons.check : Icons.schedule,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textHint),
        ],
      ),
    );
  }
}
