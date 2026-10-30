import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Botón principal (verde lleno). Estados: normal, presionado, deshabilitado, cargando.
/// `color: AppColors.primaryDark` para acciones de flujo (Continuar, Guardar).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.loadingLabel,
    this.color = AppColors.primary,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? loadingLabel;
  final Color color;
  final IconData? icon;

  /// false = ancho según contenido (ej. "Sincronizar ahora").
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        disabledBackgroundColor: isLoading ? AppColors.primaryDisabled : AppColors.border,
        disabledForegroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
        textStyle: AppText.button,
      ),
      child: _ButtonContent(label: isLoading ? (loadingLabel ?? label) : label, icon: isLoading ? null : icon),
    );
    return SizedBox(width: expand ? double.infinity : null, height: AppSpacing.buttonHeight, child: button);
  }
}

/// Botón secundario con borde (Volver al mapa, Ver historial, Ir al inicio...).
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.primaryDark,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: expand ? double.infinity : null,
      height: AppSpacing.buttonHeight,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          backgroundColor: AppColors.background,
          side: BorderSide(color: onPressed == null ? AppColors.border : color),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
          textStyle: AppText.button,
        ),
        child: _ButtonContent(label: label, icon: icon),
      ),
    );
  }
}

/// Acción destructiva (Cerrar sesión, descartar). Mismo formato que el secundario, en rojo.
class DestructiveButton extends StatelessWidget {
  const DestructiveButton({super.key, required this.label, required this.onPressed, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) =>
      SecondaryButton(label: label, onPressed: onPressed, icon: icon, color: AppColors.error);
}

/// Variantes del botón de solo ícono.
enum AppIconButtonVariant {
  /// Sin fondo (barras superiores).
  plain,

  /// Círculo blanco con sombra (sobre el mapa).
  floating,

  /// Círculo oscuro translúcido (sobre la cámara).
  overlay,

  /// Círculo verde suave.
  soft,
}

/// Botón de solo ícono. El `tooltip` es obligatorio: es la etiqueta accesible.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.variant = AppIconButtonVariant.plain,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final AppIconButtonVariant variant;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, double elevation) = switch (variant) {
      AppIconButtonVariant.plain => (Colors.transparent, AppColors.textPrimary, 0.0),
      AppIconButtonVariant.floating => (AppColors.background, AppColors.textPrimary, 3.0),
      AppIconButtonVariant.overlay => (AppColors.overlayDark, Colors.white, 0.0),
      AppIconButtonVariant.soft => (AppColors.primaryLight, AppColors.primaryDark, 0.0),
    };
    return Material(
      color: bg,
      shape: const CircleBorder(),
      elevation: elevation,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: AppIconSize.md, color: color ?? fg),
      ),
    );
  }
}

/// Enlace verde (¿Olvidó su contraseña?, Volver a iniciar sesión).
class AppLinkButton extends StatelessWidget {
  const AppLinkButton({super.key, required this.label, required this.onPressed, this.fontSize = 12});

  final String label;
  final VoidCallback? onPressed;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: AppText.link.copyWith(fontSize: fontSize)),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({required this.label, this.icon});
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: AppSpacing.sm)],
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      );
}
