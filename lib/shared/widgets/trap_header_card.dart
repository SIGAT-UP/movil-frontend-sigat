import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';

/// Tarjeta de trampa ICA: ícono, código, subtítulo y badge opcional
/// (Registrar lectura, Trampa identificada).
class TrapHeaderCard extends StatelessWidget {
  const TrapHeaderCard({super.key, required this.code, this.subtitle, this.badge, this.large = false});

  final String code;
  final String? subtitle;
  final String? badge;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      tone: AppCardTone.highlighted,
      borderColor: AppColors.primary,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: large ? 44 : 38,
            height: large ? 44 : 38,
            decoration: const BoxDecoration(color: AppColors.primaryDark, shape: BoxShape.circle),
            child: const Icon(Icons.lightbulb_outline, color: Colors.white, size: AppIconSize.md),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(code, style: large ? AppText.h1 : AppText.h2),
                if (subtitle != null) Text(subtitle!, style: AppText.caption),
                if (badge != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  StatusBadge(badge!, icon: Icons.check),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
