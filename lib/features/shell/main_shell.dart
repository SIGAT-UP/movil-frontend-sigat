import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../app/shell_nav.dart';
import '../../core/widgets/widgets.dart';
import '../home/home_screen.dart';
import '../map/map_screen.dart';
import '../profile/profile_screen.dart';
import '../traps/traps_tab_screen.dart';
import '../visit/visit_in_progress_screen.dart';
import 'role_side_parts.dart';

/// Contenedor del TÉCNICO (5 pestañas). Móvil: barra inferior. Web/tablet: menú lateral.
/// Las pantallas del flujo (lotes, detalle, lectura...) se abren encima con Navigator.
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleShell<AppTab>(
      nav: ShellNav.nav,
      sideHeader: const RoleSideHeader(),
      sideFooter: const RoleSideFooter(),
      tabs: {
        AppTab.inicio: RoleTab(
          item: const AppNavItem('Inicio', Icons.home_outlined, Icons.home),
          page: HomeScreen(
            onOpenLots: () => Navigator.of(context).pushNamed(AppRoutes.lots),
            onOpenSync: () => Navigator.of(context).pushNamed(AppRoutes.sync),
          ),
        ),
        AppTab.mapa: const RoleTab(item: AppNavItem('Mapa', Icons.map_outlined, Icons.map), page: MapScreen()),
        AppTab.trampas: const RoleTab(item: AppNavItem('Trampas', Icons.format_list_bulleted), page: TrapsTabScreen()),
        AppTab.visita: const RoleTab(
            item: AppNavItem('Visita', Icons.fact_check_outlined, Icons.fact_check), page: VisitInProgressScreen()),
        AppTab.mas: const RoleTab(item: AppNavItem('Más', Icons.more_horiz), page: ProfileScreen()),
      },
    );
  }
}
