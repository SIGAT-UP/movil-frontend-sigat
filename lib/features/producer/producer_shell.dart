import 'package:flutter/material.dart';

import '../../app/shell_nav.dart';
import '../../core/widgets/widgets.dart';
import '../profile/profile_screen.dart';
import '../shell/role_side_parts.dart';
import 'crop_status_screen.dart';
import 'producer_history_screen.dart';
import 'producer_home_screen.dart';

/// Contenedor del PRODUCTOR (4 pestañas). Mismo [RoleShell] que el técnico,
/// con SUS opciones: nunca ve Mapa, Trampas ni Visita.
class ProducerShell extends StatelessWidget {
  const ProducerShell({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleShell<ProducerTab>(
      nav: ProducerNav.nav,
      sideHeader: const RoleSideHeader(),
      sideFooter: const RoleSideFooter(),
      tabs: const {
        ProducerTab.inicio: RoleTab(item: AppNavItem('Inicio', Icons.home_outlined, Icons.home), page: ProducerHomeScreen()),
        ProducerTab.cultivo: RoleTab(item: AppNavItem('Mi cultivo', Icons.eco_outlined, Icons.eco), page: CropStatusScreen()),
        ProducerTab.historial: RoleTab(item: AppNavItem('Historial', Icons.history), page: ProducerHistoryScreen()),
        ProducerTab.perfil: RoleTab(item: AppNavItem('Perfil', Icons.person_outline, Icons.person), page: ProfileScreen()),
      },
    );
  }
}
