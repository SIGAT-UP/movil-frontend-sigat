import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Indicador de pasos de un asistente: 1 → 2 → 3.
/// Los pasos ya completados muestran un check.
/// Se usa en "Nueva asignación" y "Nueva planeación" del Agrónomo.
class WizardSteps extends StatelessWidget {
  const WizardSteps({super.key, required this.labels, required this.current});

  final List<String> labels;

  /// Índice del paso actual, empezando en 0.
  final int current;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Paso ${current + 1} de ${labels.length}: ${labels[current]}',
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 18),
                  color: i <= current ? AppColors.primary : AppColors.border,
                ),
              ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i <= current ? AppColors.primary : AppColors.background,
                    border: Border.all(
                      color: i <= current ? AppColors.primary : AppColors.border,
                      width: 1.5,
                    ),
                  ),
                  child: i < current
                      ? const Icon(Icons.check, size: 15, color: Colors.white)
                      : Center(
                          child: Text(
                            '${i + 1}',
                            style: AppText.caption.copyWith(
                              fontWeight: FontWeight.w800,
                              color: i == current ? Colors.white : AppColors.textHint,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 4),
                Text(
                  labels[i],
                  style: AppText.micro.copyWith(
                    fontWeight: i == current ? FontWeight.w700 : FontWeight.w500,
                    color: i <= current ? AppColors.primaryDark : AppColors.textHint,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Barra inferior de un asistente: "Atrás" + acción principal.
class WizardActions extends StatelessWidget {
  const WizardActions({
    super.key,
    required this.nextLabel,
    required this.onNext,
    this.onBack,
    this.isLoading = false,
  });

  final String nextLabel;
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.background, boxShadow: AppShadows.nav),
      child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.sm, AppSpacing.screenH, AppSpacing.md),
        child: Row(
          children: [
            if (onBack != null) ...[
              Expanded(
                child: SizedBox(
                  height: AppSpacing.buttonHeight,
                  child: OutlinedButton(
                    onPressed: isLoading ? null : onBack,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryDark,
                      side: const BorderSide(color: AppColors.primaryDark),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                      textStyle: AppText.button,
                    ),
                    child: const Text('Atrás'),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: SizedBox(
                height: AppSpacing.buttonHeight,
                child: FilledButton(
                  onPressed: isLoading ? null : onNext,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    disabledBackgroundColor: isLoading ? AppColors.primaryDisabled : AppColors.border,
                    disabledForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                    textStyle: AppText.button,
                  ),
                  child: Text(isLoading ? 'Guardando...' : nextLabel),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
