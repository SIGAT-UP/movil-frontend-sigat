import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/widgets/widgets.dart';
import '../../data/app_services.dart';
import '../../data/models/user_session.dart';
import 'logout.dart';

/// A03 — Contexto de acceso: confirma usuario, rol, alcance y conexión.
class AccessContextScreen extends StatelessWidget {
  const AccessContextScreen({super.key});

  String _roleMessage(UserRole role) => switch (role) {
        UserRole.tecnico => 'Podrás registrar lecturas, trabajar sin conexión y sincronizar.',
        UserRole.agronomo =>
          'Podrás revisar los registros de campo, consultar el resumen del lote y planear las actividades.',
        UserRole.coordinador => 'Podrás consultar el avance de los técnicos y los reportes de tu zona.',
        UserRole.productor =>
          'Podrás consultar el estado de tu cultivo, registrar aplicaciones y cosechas, trabajar sin conexión y sincronizar.',
        UserRole.administrador => 'Podrás gestionar usuarios, predios y catálogos.',
        UserRole.desconocido =>
          'Tu cuenta no tiene un rol reconocido por esta versión de la app. Comunícate con el administrador.',
      };

  @override
  Widget build(BuildContext context) {
    final session = AppServices.session.value;
    if (session == null) {
      // Sin sesión no se puede estar aquí.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => Navigator.of(context).pushReplacementNamed(AppRoutes.login),
      );
      return const Scaffold();
    }

    // Atrás (barra o sistema) = "no soy yo / cambiar de usuario": cierra la
    // sesión recién abierta y vuelve al login. Sin él, el atrás del sistema
    // cerraría la app.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) logoutNow(context);
      },
      child: Scaffold(
      appBar: SimpleAppBar(
        title: 'Acceso',
        onBack: () => logoutNow(context),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.md),
                      const BrandLogo(size: 52),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Hola, ${session.firstName}',
                          style: AppText.display),
                      const SizedBox(height: 2),
                      const Text('Este es tu acceso al sistema',
                          style: AppText.secondary),
                      const SizedBox(height: AppSpacing.lg),
                      ValueListenableBuilder<bool>(
                        valueListenable: AppServices.isOnline,
                        builder: (_, online, __) => InfoTableCard(rows: [
                          InfoRowData('Usuario', value: session.displayName),
                          InfoRowData('Rol', value: session.role.label),
                          InfoRowData('Lote', value: session.scope),
                          InfoRowData('Dispositivo', value: session.device),
                          InfoRowData('Conexión', trailing: ConnectionChip(isOnline: online)),
                        ]),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AlertBanner(
                        type: AlertType.info,
                        title: 'Verás solo lo de tu rol',
                        message: _roleMessage(session.role),
                      ),
                    ],
                  ),
                ),
              ),
              PrimaryButton(
                label: 'Continuar',
                color: AppColors.primaryDark,
                onPressed: () {
                  // Cada rol entra a SU inicio; nunca ve las pantallas de otro rol.
                  final route = AppRoutes.homeFor(session.role);
                  if (route == null) {
                    AppMessenger.warning(
                      'Tu rol todavía no tiene vistas en esta versión',
                      message: 'Comunícate con el administrador del sistema.',
                    );
                    return;
                  }
                  Navigator.of(context).pushNamedAndRemoveUntil(route, (_) => false);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: TextButton(
                  onPressed: () => logoutNow(context),
                  child: const Text('No soy yo · cambiar de usuario'),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
