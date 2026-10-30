import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../data/app_services.dart';
import '../../data/models/trap.dart';
import '../visit/visit_controller.dart';

/// Busca una trampa por código validándola contra el lote activo.
Future<TrapLookup?> lookupTrap(String code) =>
    AppServices.traps.findByCode(code, activeLotId: VisitController.instance.activeLot?.id);

/// Abre "Trampa identificada". `replace` cierra la pantalla actual (escáner / código).
void openTrapIdentified(BuildContext context, TrapLookup lookup, {bool replace = false}) {
  final nav = Navigator.of(context);
  if (replace) {
    nav.pushReplacementNamed(AppRoutes.trapIdentified, arguments: lookup);
  } else {
    nav.pushNamed(AppRoutes.trapIdentified, arguments: lookup);
  }
}
