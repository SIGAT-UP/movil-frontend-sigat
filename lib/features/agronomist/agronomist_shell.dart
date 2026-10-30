import 'package:flutter/material.dart';

import '../../app/shell_nav.dart';
import '../../core/widgets/widgets.dart';
import '../profile/profile_screen.dart';
import '../shell/role_side_parts.dart';
import 'agronomist_home_screen.dart';
import 'lot_history_screen.dart';
import 'record_traps_screen.dart';
import 'records_screen.dart';

/// Contenedor del AGRÓNOMO (5 pestañas). Mismo [RoleShell] que los demás
/// roles, con SUS opciones: no ve Mapa ni Visita (no hace trabajo de campo).
class AgronomistShell extends StatelessWidget {
  const AgronomistShell({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleShell<AgronomistTab>(
      nav: AgronomistNav.nav,
      sideHeader: const RoleSideHeader(),
      sideFooter: const RoleSideFooter(),
      tabs: const {
        AgronomistTab.inicio: RoleTab(
          item: AppNavItem('Inicio', Icons.home_outlined, Icons.home),
          page: AgronomistHomeScreen(),
        ),
        AgronomistTab.trampas: RoleTab(
          item: AppNavItem('Trampas', Icons.lightbulb_outline, Icons.lightbulb),
          page: RecordTrapsScreen(
            title: 'Trampas',
            showBack: false,
          ),
        ),
        AgronomistTab.revisiones: RoleTab(
          item: AppNavItem('Revisiones', Icons.fact_check_outlined, Icons.fact_check),
          page: RecordsScreen(showBack: false),
        ),
        AgronomistTab.historial: RoleTab(
          item: AppNavItem('Historial', Icons.history),
          page: LotHistoryScreen(showBack: false),
        ),
        AgronomistTab.perfil: RoleTab(
          item: AppNavItem('Perfil', Icons.person_outline, Icons.person),
          page: ProfileScreen(),
        ),
      },
    );
  }
}
