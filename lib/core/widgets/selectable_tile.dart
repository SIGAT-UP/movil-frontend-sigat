import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'brand.dart';

/// Fila seleccionable con círculo a la derecha.
/// Se usa en los selectores de técnico, productor y lote del Agrónomo.
/// `multiple: true` dibuja la marca de selección múltiple.
class SelectableTile extends StatelessWidget {
  const SelectableTile({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.avatarName,
    this.multiple = false,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  /// Si se indica, se dibuja un avatar con las iniciales de ese nombre.
  final String? avatarName;
  final bool multiple;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.selectedTint : AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                if (avatarName != null) ...[
                  UserAvatar(name: avatarName!, radius: 16),
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppText.title),
                      if (subtitle != null) Text(subtitle!, style: AppText.caption),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.check_circle
                      : (multiple ? Icons.circle_outlined : Icons.radio_button_unchecked),
                  color: selected ? AppColors.primary : AppColors.border,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
