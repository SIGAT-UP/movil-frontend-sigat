import 'package:flutter/material.dart';

import '../theme/app_typography.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import 'status_badge.dart';

/// Fila con círculo de check + título + subtítulo.
/// Visita en curso (ICA-001 Lectura guardada), Sincronización (LOTE-A Sincronizado), etc.
class ChecklistTile extends StatelessWidget {
  const ChecklistTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.done,
    this.tone,
    this.onTap,
    this.trailing,
    this.selected = false,
    this.locked = false,
  });

  final String title;
  final String subtitle;
  final bool done;

  /// Resaltado (borde verde grueso y punto en el círculo).
  final bool selected;

  /// Bloqueado: gris, sin interacción.
  final bool locked;

  /// Si es null: verde cuando done, ámbar cuando pendiente.
  final StatusTone? tone;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = locked ? StatusTone.neutral : (tone ?? (done ? StatusTone.success : StatusTone.warning));
    final tile = Material(
      color: t.bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: locked ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.primary : t.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? t.fg : Colors.white,
                  border: done
                      ? null
                      : Border.all(color: selected ? AppColors.primary : AppColors.textHint, width: selected ? 2 : 1.5),
                ),
                child: done
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : locked
                        ? const Icon(Icons.lock_outline, size: 14, color: AppColors.textHint)
                        : selected
                            ? Center(
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                ),
                              )
                            : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.title),
                    Text(subtitle, style: AppText.caption),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
    return locked ? Opacity(opacity: .55, child: tile) : tile;
  }
}

/// Texto de avance + barra ("3 de 4 trampas registradas del lote A").
class ProgressHeader extends StatelessWidget {
  const ProgressHeader({super.key, required this.label, required this.value, this.trailing});

  final String label;

  /// 0..1
  final double value;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: AppText.label)),
            if (trailing != null)
              Text(trailing!, style: AppText.caption),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: value.clamp(0, 1),
            minHeight: 6,
            backgroundColor: AppColors.border,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

/// Fila de menú con ícono, título, subtítulo y flecha (Perfil y "Más").
class MenuTile extends StatelessWidget {
  const MenuTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.iconColor = AppColors.primary,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color iconColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(AppSpacing.radiusMd);
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: br, boxShadow: AppShadows.card),
      child: Material(
        color: AppColors.background,
        borderRadius: br,
        child: InkWell(
          onTap: onTap,
          borderRadius: br,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: br,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                // Ícono en placa cuadrada redondeada, teñida con su propio color.
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(icon, size: 22, color: iconColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppText.title),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!, style: AppText.caption),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                trailing ??
                    (onTap != null
                        ? Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(color: AppColors.surfaceRaised, shape: BoxShape.circle),
                            child: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.primaryDark),
                          )
                        : const SizedBox()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
