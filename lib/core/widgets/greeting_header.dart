import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'status_chip.dart';

/// Encabezado del inicio de cada rol.
///
///   Hola, Técnico Demo              [campana] [salir]
///   Bienvenido al sistema
///   (•) Conectado
///
/// El estado de conexión va DEBAJO del saludo, como una línea de estado, y no
/// entre el título y los íconos: así no compite con el nombre ni lo obliga a
/// partirse en dos líneas.
class GreetingHeader extends StatelessWidget {
  const GreetingHeader({
    super.key,
    required this.title,
    required this.isOnline,
    this.subtitle,
    this.actions = const [],
    this.titleStyle = AppText.h1,
  });

  final String title;
  final String? subtitle;
  final bool isOnline;

  /// Íconos a la derecha (campana, cerrar sesión).
  final List<Widget> actions;
  final TextStyle titleStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: titleStyle, maxLines: 2, overflow: TextOverflow.ellipsis),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: AppText.secondary),
              ],
              const SizedBox(height: AppSpacing.sm),
              ConnectionChip(isOnline: isOnline),
            ],
          ),
        ),
        ...actions,
      ],
    );
  }
}
