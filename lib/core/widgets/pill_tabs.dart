import 'package:flutter/material.dart';

import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

import '../theme/app_colors.dart';

/// Pestañas tipo píldora con scroll horizontal
/// ("Todos / Pendientes / En curso / Visitado", "Todas / Últimos 7 días / Pendientes").
class PillTabs extends StatelessWidget {
  const PillTabs({super.key, required this.labels, required this.selected, required this.onChanged});

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final reducir = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Semantics(
                selected: i == selected,
                button: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: reducir ? Duration.zero : const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    constraints: const BoxConstraints(minHeight: 38),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: i == selected ? AppColors.primaryDark : AppColors.background,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                      border: Border.all(color: i == selected ? AppColors.primaryDark : AppColors.border),
                    ),
                    child: Text(
                      labels[i],
                      style: AppText.link.copyWith(
                        fontSize: 13,
                        fontWeight: i == selected ? FontWeight.w700 : FontWeight.w600,
                        color: i == selected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
