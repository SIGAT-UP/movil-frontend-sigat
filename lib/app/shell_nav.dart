import 'package:flutter/material.dart';

import '../core/widgets/navigation.dart';
import 'routes.dart';

/// Pestañas del TÉCNICO.
enum AppTab { inicio, mapa, trampas, visita, mas }

/// Pestañas del PRODUCTOR.
enum ProducerTab { inicio, cultivo, historial, perfil }

/// Pestañas del AGRÓNOMO.
enum AgronomistTab { inicio, trampas, revisiones, historial, perfil }

/// Navegación del técnico. Cada rol tiene su propio [RoleNav]: las opciones no se mezclan.
class ShellNav {
  ShellNav._();

  static final nav = RoleNav<AppTab>(homeRoute: AppRoutes.home, initial: AppTab.inicio);
  static ValueNotifier<AppTab> get tab => nav.tab;

  /// Ej.: después de "Guardar lectura" → ShellNav.goTo(context, AppTab.visita).
  static void goTo(BuildContext context, AppTab target) => nav.goTo(context, target);
}

/// Navegación del productor.
class ProducerNav {
  ProducerNav._();

  static final nav = RoleNav<ProducerTab>(homeRoute: AppRoutes.producerHome, initial: ProducerTab.inicio);
  static ValueNotifier<ProducerTab> get tab => nav.tab;

  static void goTo(BuildContext context, ProducerTab target) => nav.goTo(context, target);
}

/// Navegación del agrónomo.
class AgronomistNav {
  AgronomistNav._();

  static final nav =
      RoleNav<AgronomistTab>(homeRoute: AppRoutes.agronomistHome, initial: AgronomistTab.inicio);
  static ValueNotifier<AgronomistTab> get tab => nav.tab;

  static void goTo(BuildContext context, AgronomistTab target) => nav.goTo(context, target);
}
