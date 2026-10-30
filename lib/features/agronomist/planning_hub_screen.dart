
import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/planning.dart';

/// Planeación del Agrónomo: dos caminos, uno por destinatario.
///  * Iniciar planeación → planeaciones para PRODUCTORES.
///  * Asignar lotes      → asignaciones para TÉCNICOS.
/// Cada uno abre su propio menú con "Nueva" y "Mis …".
class PlanningHubScreen extends StatelessWidget {
  const PlanningHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SimpleAppBar(title: 'Planeación'),
      body: ResponsiveBody(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenH),
          children: [
            const SizedBox(height: AppSpacing.lg),
            const _Ilustracion(
              icon: Icons.assignment_ind_outlined,
              imagePath: 'assets/images/planeacion.png',
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Programa las actividades de los productores y asigna lotes a los técnicos',
              textAlign: TextAlign.center,
              style: AppText.secondary,
            ),
            const SizedBox(height: AppSpacing.xl),
            MenuTile(
              icon: Icons.show_chart,
              title: 'Iniciar planeación',
              subtitle: 'Actividades para los productores',
              onTap: () => Navigator.of(context).pushNamed(
                AppRoutes.agroPlanningTarget,
                arguments: PlanningTarget.productor,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            MenuTile(
              icon: Icons.eco_outlined,
              title: 'Asignar lotes',
              subtitle: 'Lotes y fechas para los técnicos',
              onTap: () => Navigator.of(context).pushNamed(
                AppRoutes.agroPlanningTarget,
                arguments: PlanningTarget.tecnico,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Menú de un destinatario: crear una nueva o ver las que ya se hicieron.
class PlanningTargetHubScreen extends StatelessWidget {
  const PlanningTargetHubScreen({super.key, required this.target});

  final PlanningTarget target;

  bool get _productor => target == PlanningTarget.productor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: SimpleAppBar(
        title: _productor ? 'Planeación' : 'Asignación de lotes',
      ),
      body: ResponsiveBody(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenH),
          children: [
            const SizedBox(height: AppSpacing.lg),
            _Ilustracion(
              icon: _productor
                  ? Icons.calendar_month_outlined
                  : Icons.map_outlined,
              imagePath: 'assets/images/planeacion1.png',
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _productor
                  ? 'Programa las asignaciones para los productores'
                  : 'Asigna lotes y fechas a los técnicos',
              textAlign: TextAlign.center,
              style: AppText.label,
            ),
            const SizedBox(height: AppSpacing.xl),
            MenuTile(
              icon: Icons.add_circle_outline,
              title: _productor ? 'Nueva planeación' : 'Nueva asignación',
              subtitle: _productor
                  ? 'Datos, instrucciones y confirmación'
                  : 'Técnico, lotes y fechas',
              onTap: () => Navigator.of(context).pushNamed(
                AppRoutes.agroNewPlanning,
                arguments: target,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            MenuTile(
              icon: Icons.fact_check_outlined,
              title: _productor
                  ? 'Mis planificaciones'
                  : 'Mis asignaciones',
              subtitle: 'Fechas, respuestas y motivos de rechazo',
              iconColor: AppColors.primaryDark,
              onTap: () => Navigator.of(context).pushNamed(
                AppRoutes.agroMyPlannings,
                arguments: target,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ilustración sin fondo circular y con imágenes grandes.
class _Ilustracion extends StatelessWidget {
  const _Ilustracion({
    required this.icon,
    required this.imagePath,
  });

  final IconData icon;
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 170,
        height: 170,
        child: Image.asset(
          imagePath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Muestra el ícono original si la imagen no está disponible.
            return Icon(
              icon,
              size: 80,
              color: AppColors.primaryDark,
            );
          },
        ),
      ),
    );
  }
}
