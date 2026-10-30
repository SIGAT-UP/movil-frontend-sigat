import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Diálogo de confirmación estándar. Devuelve true si el usuario confirma.
/// `destructive: true` pinta la acción en rojo (cerrar sesión, descartar).
Future<bool> showAppConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Aceptar',
  String cancelLabel = 'Cancelar',
  bool destructive = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: AppText.h3),
      content: Text(message, style: AppText.body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(cancelLabel)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: destructive ? AppColors.error : AppColors.primaryDark),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Protege un formulario a medio llenar.
///
/// Si `hasChanges` es true, el botón atrás de la barra (que usa `maybePop`)
/// y el atrás del sistema piden confirmación antes de salir. Si es false,
/// se sale sin preguntar. Envolver el `Scaffold` del formulario:
///
/// ```dart
/// DiscardChangesGuard(hasChanges: _dirty, child: Scaffold(...))
/// ```
class DiscardChangesGuard extends StatelessWidget {
  const DiscardChangesGuard({
    super.key,
    required this.hasChanges,
    required this.child,
    this.message = 'Lo que escribiste en este formulario se perderá.',
  });

  final bool hasChanges;
  final Widget child;
  final String message;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final salir = await showAppConfirmDialog(
          context,
          title: '¿Salir sin guardar?',
          message: message,
          confirmLabel: 'Salir sin guardar',
          cancelLabel: 'Seguir editando',
          destructive: true,
        );
        if (salir && context.mounted) Navigator.of(context).pop();
      },
      child: child,
    );
  }
}
