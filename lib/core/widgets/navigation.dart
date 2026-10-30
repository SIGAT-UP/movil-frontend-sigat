import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Ítem de navegación (pestaña inferior o entrada del menú lateral).
class AppNavItem {
  const AppNavItem(this.label, this.icon, [this.activeIcon]);
  final String label;
  final IconData icon;
  final IconData? activeIcon;
}

/// Pestaña de un rol: ítem visible + pantalla.
class RoleTab {
  const RoleTab({required this.item, required this.page});
  final AppNavItem item;
  final Widget page;
}

/// Estado de navegación de un rol: pestaña activa + ruta raíz del rol.
/// Cada rol tiene SU instancia, así nunca se mezclan las opciones entre roles.
class RoleNav<T extends Enum> {
  RoleNav({required this.homeRoute, required this.initial}) : tab = ValueNotifier<T>(initial);

  final String homeRoute;
  final T initial;
  final ValueNotifier<T> tab;

  /// Cierra las pantallas abiertas encima del menú del rol y cambia de pestaña.
  void goTo(BuildContext context, T target) {
    Navigator.of(context).popUntil((r) => r.settings.name == homeRoute || r.isFirst);
    tab.value = target;
  }

  void reset() => tab.value = initial;
}

/// Contenedor de un rol. Adapta la navegación al ancho disponible:
///  * móvil (< [AppSpacing.wideBreakpoint]): barra inferior.
///  * web / tablet: menú lateral con marca y pie (usuario, conexión).
/// Cada pestaña conserva su estado (IndexedStack).
class RoleShell<T extends Enum> extends StatelessWidget {
  const RoleShell({super.key, required this.nav, required this.tabs, this.sideHeader, this.sideFooter});

  final RoleNav<T> nav;

  /// Pestañas del rol en orden.
  final Map<T, RoleTab> tabs;

  /// Solo en web: cabecera y pie del menú lateral.
  final Widget? sideHeader;
  final Widget? sideFooter;

  @override
  Widget build(BuildContext context) {
    final keys = tabs.keys.toList();
    final items = [for (final t in tabs.values) t.item];
    final pages = [for (final t in tabs.values) t.page];

    return ValueListenableBuilder<T>(
      valueListenable: nav.tab,
      builder: (context, current, _) {
        final index = keys.contains(current) ? keys.indexOf(current) : 0;
        void select(int i) => nav.tab.value = keys[i];
        // IndexedStack conserva el estado de cada pestaña; _TabFade solo
        // anima la aparición de la que se acaba de elegir.
        final body = _TabFade(index: index, child: IndexedStack(index: index, children: pages));

        // Botón atrás del sistema (Android, gesto, navegador): en cualquier
        // pestaña que no sea la inicial vuelve a Inicio en lugar de cerrar la
        // app. Solo desde Inicio se sale.
        return PopScope(
          canPop: current == nav.initial,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) nav.tab.value = nav.initial;
          },
          child: _layout(items, index, select, body),
        );
      },
    );
  }

  Widget _layout(List<AppNavItem> items, int index, void Function(int) select, Widget body) {
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth >= AppSpacing.wideBreakpoint) {
        return Scaffold(
          backgroundColor: AppColors.surface,
          body: Row(
            children: [
              AppSideNav(items: items, currentIndex: index, onTap: select, header: sideHeader, footer: sideFooter),
              const VerticalDivider(width: 1, color: AppColors.border),
              Expanded(child: body),
            ],
          ),
        );
      }
      return Scaffold(
        // Gris hoja detrás de las esquinas redondeadas de la barra inferior.
        backgroundColor: AppColors.surface,
        body: body,
        bottomNavigationBar: AppBottomNav(items: items, currentIndex: index, onTap: select),
      );
    });
  }
}

/// Barra inferior (móvil).
///
/// Flota sobre el contenido con esquinas redondeadas y sombra hacia arriba.
/// La pestaña activa lleva una píldora verde que crece detrás del ícono; las
/// inactivas usan un gris con contraste suficiente para leerse al sol.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.items, required this.currentIndex, required this.onTap});

  final List<AppNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: AppShadows.nav,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, 6),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _BottomNavButton(
                    item: items[i],
                    active: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavButton extends StatelessWidget {
  const _BottomNavButton({required this.item, required this.active, required this.onTap});
  final AppNavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final duracion = _motion(context, const Duration(milliseconds: 260));
    return Semantics(
      container: true,
      selected: active,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: () {
          if (!active) HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: duracion,
                curve: Curves.easeOutCubic,
                width: active ? 60 : 40,
                height: 32,
                decoration: BoxDecoration(
                  color: active ? AppColors.primaryLight : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
                child: Icon(
                  active ? (item.activeIcon ?? item.icon) : item.icon,
                  size: 24,
                  color: active ? AppColors.primaryDark : AppColors.navIdle,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: duracion,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  color: active ? AppColors.navInk : AppColors.navIdle,
                ),
                child: Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Menú lateral (web / tablet).
///
/// Panel en verde de huerto profundo: separa con claridad la navegación del
/// contenido, que queda sobre el gris hoja. La entrada activa se eleva un tono
/// y lleva un brote verde claro a la izquierda.
class AppSideNav extends StatelessWidget {
  const AppSideNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.header,
    this.footer,
    this.width = 240,
  });

  final List<AppNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Widget? header;
  final Widget? footer;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      color: AppColors.navInk,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (header != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg),
                child: header,
              ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Divider(height: 1, color: Color(0x1FFFFFFF)),
            ),
            const SizedBox(height: AppSpacing.md),
            for (var i = 0; i < items.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 3),
                child: _SideNavButton(item: items[i], active: i == currentIndex, onTap: () => onTap(i)),
              ),
            const Spacer(),
            if (footer != null)
              Container(
                margin: const EdgeInsets.all(AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.navInkRaised,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: footer,
              ),
          ],
        ),
      ),
    );
  }
}

class _SideNavButton extends StatelessWidget {
  const _SideNavButton({required this.item, required this.active, required this.onTap});
  final AppNavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final duracion = _motion(context, const Duration(milliseconds: 220));
    final br = BorderRadius.circular(AppSpacing.radiusMd);
    return Semantics(
      container: true,
      selected: active,
      button: true,
      child: AnimatedContainer(
        duration: duracion,
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: active ? AppColors.navInkRaised : Colors.transparent,
          borderRadius: br,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: br,
            hoverColor: const Color(0x14FFFFFF),
            splashColor: const Color(0x1FFFFFFF),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.md, AppSpacing.md, AppSpacing.md),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: duracion,
                    width: 3,
                    height: active ? 22 : 0,
                    decoration: BoxDecoration(
                      color: AppColors.navSprout,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Icon(
                    active ? (item.activeIcon ?? item.icon) : item.icon,
                    size: 22,
                    color: active ? AppColors.navOnInk : AppColors.navOnInkMuted,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      item.label,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.label.copyWith(
                        fontSize: 14,
                        fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                        color: active ? AppColors.navOnInk : AppColors.navOnInkMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Aparición de la pestaña recién elegida: fundido y un leve ascenso (180 ms).
/// No reconstruye las pestañas: solo envuelve el IndexedStack.
class _TabFade extends StatefulWidget {
  const _TabFade({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  State<_TabFade> createState() => _TabFadeState();
}

class _TabFadeState extends State<_TabFade> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 180), value: 1);

  static final _opacidad = CurveTween(curve: Curves.easeOut);
  static final _subida =
      Tween(begin: const Offset(0, 0.012), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic));

  @override
  void didUpdateWidget(covariant _TabFade old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) {
      final reducir = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (reducir) {
        _c.value = 1;
      } else {
        _c.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _c.drive(_opacidad),
        child: SlideTransition(position: _c.drive(_subida), child: widget.child),
      );
}

/// Duración de una animación, o cero si el sistema pide reducir el movimiento.
Duration _motion(BuildContext context, Duration d) =>
    (MediaQuery.maybeOf(context)?.disableAnimations ?? false) ? Duration.zero : d;
