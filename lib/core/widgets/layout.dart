import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Encabezado móvil: flecha atrás + título + acciones (ej. "Guardado local").
class SimpleAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SimpleAppBar({super.key, required this.title, this.actions, this.showBack = true, this.onBack});

  final String title;
  final List<Widget>? actions;
  final bool showBack;

  /// Acción del botón atrás cuando la pantalla es una pestaña (no hay a dónde hacer pop).
  final VoidCallback? onBack;

  static const double _height = 60;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    final canBack = showBack && (onBack != null || Navigator.of(context).canPop());
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: _height,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      leadingWidth: canBack ? 64 : null,
      leading: canBack
          ? Center(
              child: IconButton(
                tooltip: 'Atrás',
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded, size: 22),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surfaceRaised,
                  foregroundColor: AppColors.primaryDark,
                  fixedSize: const Size(42, 42),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                ),
              ),
            )
          : null,
      titleSpacing: canBack ? 2 : AppSpacing.screenH,
      title: Text(title, style: AppText.h2, maxLines: 1, overflow: TextOverflow.ellipsis),
      actions: [...?actions, const SizedBox(width: AppSpacing.sm)],
      shape: const Border(bottom: BorderSide(color: AppColors.border)),
    );
  }
}

/// Indicador de guardado local en el encabezado.
class LocalStorageBadge extends StatelessWidget {
  const LocalStorageBadge({super.key, this.label = 'Guardado local'});
  final String label;

  @override
  Widget build(BuildContext context) => Center(child: Text(label, style: AppText.overline));
}

/// Limita el ancho del contenido en pantallas anchas (web) y lo centra.
/// En móvil no cambia nada.
class ResponsiveBody extends StatelessWidget {
  const ResponsiveBody({super.key, required this.child, this.maxWidth = AppSpacing.maxContentWidth});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        // heightFactor 1: alto = el del hijo (no se estira dentro de la barra inferior).
        heightFactor: 1,
        child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
      );
}

/// Zona fija inferior para 1 o 2 botones (Guardar, Continuar, Finalizar...).
class BottomActions extends StatelessWidget {
  const BottomActions({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    // Panel blanco anclado al borde inferior, con la misma sombra que la barra
    // de navegación: las acciones se leen como "lo que sigue" y no se pierden
    // entre el contenido.
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.background, boxShadow: AppShadows.nav),
      child: SafeArea(
        top: false,
        child: ResponsiveBody(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.md, AppSpacing.screenH, AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  children[i],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Título de sección ("Tu jornada", "Actividad reciente", "Fecha esperada").
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing, this.style = AppText.h3});
  final String text;
  final Widget? trailing;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: Text(text, style: style)),
          if (trailing != null) trailing!,
        ],
      );
}

/// Estado vacío genérico (sin lotes, sin historial, sin visita activa...).
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.message, this.action});
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Doble anillo: el ícono se lee como el centro de una hoja vacía.
            Container(
              width: 88,
              height: 88,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: .5),
                shape: BoxShape.circle,
              ),
              child: Container(
                decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                child: Icon(icon, size: 30, color: AppColors.primaryDark),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title, textAlign: TextAlign.center, style: AppText.h3),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(message!, textAlign: TextAlign.center, style: AppText.secondary),
            ],
            if (action != null) ...[const SizedBox(height: AppSpacing.lg), action!],
          ],
        ),
      ),
    );
  }
}
