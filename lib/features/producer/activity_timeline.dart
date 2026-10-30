import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';
import '../../data/models/producer.dart';

/// Adaptador: convierte el historial del productor en la [TimelineList] global.
class ActivityTimeline extends StatelessWidget {
  const ActivityTimeline({super.key, required this.records, this.showYear = true});
  final List<ActivityRecord> records;
  final bool showYear;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const EmptyState(icon: Icons.history, title: 'Sin actividad', message: 'Aún no hay registros.');
    }
    return TimelineList(entries: [
      for (final r in records)
        TimelineEntry(
          dateLabel: showYear ? '${Fmt.dayMonthUpper(r.date)} ${r.date.year}' : Fmt.dayMonthUpper(r.date),
          title: r.title,
          subtitle: r.subtitle,
        ),
    ]);
  }
}
