import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'asset_or_fallback.dart';

/// Variante visual de una tarjeta.
enum AppCardTone {
  /// Blanca con borde gris.
  normal,

  /// Fondo verde suave con borde verde (bloques destacados).
  highlighted,

  /// Blanca con borde verde (elemento seleccionado o principal).
  outlined,
}

/// Contenedor base de TODAS las tarjetas. Si hay `onTap`, tiene estado presionado/hover.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.tone = AppCardTone.normal,
    this.borderColor,
    this.color,
    this.radius = AppSpacing.radiusMd,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final AppCardTone tone;

  /// Sobrescriben el tono solo cuando hace falta un caso puntual.
  final Color? borderColor;
  final Color? color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color bd) = switch (tone) {
      AppCardTone.normal => (AppColors.background, AppColors.border),
      AppCardTone.highlighted => (AppColors.surfaceTint, AppColors.successBorder),
      AppCardTone.outlined => (AppColors.background, AppColors.primary),
    };
    final br = BorderRadius.circular(radius);
    return Material(
      color: color ?? bg,
      borderRadius: br,
      child: InkWell(
        onTap: onTap,
        borderRadius: br,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: br,
            border: Border.all(color: borderColor ?? bd),
            boxShadow: AppShadows.card,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Datos de una fila clave-valor. El valor puede ser texto o un widget (badge, chip).
class InfoRowData {
  const InfoRowData(this.label, {this.value, this.trailing});
  final String label;
  final String? value;
  final Widget? trailing;
}

/// Fila de información "Etiqueta ........ Valor". Se usa sola o dentro de [InfoTableCard].
class InfoRow extends StatelessWidget {
  const InfoRow(this.data, {super.key, this.padding = const EdgeInsets.symmetric(vertical: 12)});
  final InfoRowData data;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Text(data.label, style: AppText.secondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: data.trailing ??
                  Text(data.value ?? '-', textAlign: TextAlign.right, style: AppText.bodySmStrong),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de resumen: título opcional + filas clave-valor + nota.
/// Contexto de acceso, Detalle del lote, Finalizar lote/visita, Estado de mi cultivo, Cosecha registrada.
class InfoTableCard extends StatelessWidget {
  const InfoTableCard({
    super.key,
    required this.rows,
    this.title,
    this.footer,
    this.highlighted = false,
    this.showDividers = true,
  });

  final List<InfoRowData> rows;

  /// Título verde pequeño (ej. "Resumen de la visita", "Control vigente").
  final String? title;

  /// Nota pequeña al final (ej. aclaración de que el valor es estimado).
  final String? footer;

  final bool highlighted;
  final bool showDividers;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      tone: highlighted ? AppCardTone.highlighted : AppCardTone.normal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(padding: const EdgeInsets.only(top: 12, bottom: 2), child: Text(title!, style: AppText.overline)),
          for (var i = 0; i < rows.length; i++) ...[
            InfoRow(rows[i]),
            if (showDividers && i < rows.length - 1) const Divider(height: 1, color: AppColors.divider),
          ],
          if (footer != null)
            Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(footer!, style: AppText.micro)),
        ],
      ),
    );
  }
}

/// Tarjeta de acción con ícono grande, título, descripción y flecha ("Mis Lotes Asignados").
class NavActionCard extends StatelessWidget {
  const NavActionCard({super.key, required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      borderColor: AppColors.primaryDark,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: AppIconSize.hero, color: AppColors.primaryDark),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.h2),
                const SizedBox(height: 2),
                Text(subtitle, style: AppText.secondary),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textPrimary),
        ],
      ),
    );
  }
}

/// Tarjeta de indicador: ilustración, número grande y etiqueta.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.value,
    required this.label,
    required this.imagePath,
    this.fallbackIcon = Icons.eco,
    this.caption,
    this.onTap,
  });

  final String value;
  final String label;
  final String imagePath;
  final IconData fallbackIcon;
  final String? caption;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: AssetOrFallback(imagePath,
                height: 64, width: double.infinity, fit: BoxFit.contain, fallbackIcon: fallbackIcon),
          ),
          const SizedBox(height: 6),
          Text(value, style: AppText.display),
          Text(label, textAlign: TextAlign.center, style: AppText.label.copyWith(fontWeight: FontWeight.w600)),
          if (caption != null) Text(caption!, style: AppText.bodySmStrong),
        ],
      ),
    );
  }
}

/// Píldora de estado de sincronización (Inicio del técnico).
class SyncStatusCard extends StatelessWidget {
  const SyncStatusCard({
    super.key,
    required this.subtitle,
    required this.trailing,
    this.title = 'Última sincronización',
    this.onTap,
  });

  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      radius: AppSpacing.radiusPill,
      color: AppColors.primaryLight,
      borderColor: AppColors.successBorder,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_upload_outlined, size: AppIconSize.xl, color: AppColors.primaryDark),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.title),
                Text(subtitle, style: AppText.caption),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          trailing,
        ],
      ),
    );
  }
}
