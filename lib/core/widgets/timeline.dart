import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class TimelineEntry {
  const TimelineEntry({required this.dateLabel, required this.title, this.subtitle, this.trailing});
  final String dateLabel; // "08 OCT 2026"
  final String title;
  final String? subtitle;
  final Widget? trailing; // ej. StatusBadge
}

/// Línea de tiempo vertical (Actividad reciente, Historial del productor).
class TimelineList extends StatelessWidget {
  const TimelineList({super.key, required this.entries});
  final List<TimelineEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < entries.length; i++)
          _TimelineTile(entry: entries[i], isFirst: i == 0, isLast: i == entries.length - 1),
      ],
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.entry, required this.isFirst, required this.isLast});
  final TimelineEntry entry;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                Container(width: 2, height: 14, color: isFirst ? Colors.transparent : AppColors.successBorder),
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                ),
                Expanded(child: Container(width: 2, color: isLast ? Colors.transparent : AppColors.successBorder)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadows.card,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.dateLabel, style: AppText.overline),
                          const SizedBox(height: 2),
                          Text(entry.title, style: AppText.title),
                          if (entry.subtitle != null) Text(entry.subtitle!, style: AppText.caption),
                        ],
                      ),
                    ),
                    if (entry.trailing != null) entry.trailing!,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
