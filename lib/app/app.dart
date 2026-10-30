import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/app_messenger.dart';
import 'routes.dart';

class VigilanciaDuraznoApp extends StatelessWidget {
  const VigilanciaDuraznoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIGAT',
      // Sistema global de mensajes (AppMessenger) disponible desde toda la app.
      scaffoldMessengerKey: AppMessenger.key,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.splash,
      // Se arranca SIEMPRE en la bienvenida animada (también al recargar en web).
      // Al terminar, la splash decide: inicio del rol si hay sesión, o login.
      // Hoy la sesión no se guarda en el dispositivo, así que va al login;
      // cuando se restaure el token antes de runApp, irá directo al inicio.
      onGenerateInitialRoutes: (_) => [AppRoutes.onGenerateRoute(const RouteSettings(name: AppRoutes.splash))!],
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
