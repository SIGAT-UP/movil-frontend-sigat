import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Tipo de mensaje. Define color, ícono y cuánto dura en pantalla.
enum AppMessageType {
  /// La operación TERMINÓ correctamente.
  success,

  /// Falló algo y la persona debe enterarse.
  error,

  /// Falta un dato o hay algo pendiente de atender.
  warning,

  /// Estado informativo (ej. "guardado en el dispositivo, pendiente de enviar").
  info,

  /// Operación en curso. No desaparece sola: se cierra con el controlador.
  loading,
}

/// Sistema ÚNICO de mensajes de la aplicación.
///
/// Se llama desde cualquier pantalla o servicio sin necesidad de `context`:
///   AppMessenger.success('Lectura guardada');
///   AppMessenger.error('No se pudo guardar', message: 'Intenta de nuevo.');
///   final carga = AppMessenger.loading('Sincronizando...');  ... carga.close();
///
/// Reglas:
///  * `success` SOLO cuando la operación terminó de verdad. Si algo quedó
///    pendiente de enviar al servidor, se usa [pending] y se dice así.
///  * Los mensajes nunca muestran detalles técnicos ni datos personales.
///  * Un mismo mensaje repetido en pocos segundos no se vuelve a mostrar.
class AppMessenger {
  AppMessenger._();

  /// Se conecta en `MaterialApp(scaffoldMessengerKey: AppMessenger.key)`.
  static final key = GlobalKey<ScaffoldMessengerState>();

  static String? _lastSignature;
  static DateTime? _lastShownAt;

  /// Ventana en la que un mensaje idéntico se considera duplicado.
  static const _dedupeWindow = Duration(seconds: 3);

  static Duration _durationFor(AppMessageType type) => switch (type) {
        AppMessageType.success => const Duration(seconds: 3),
        AppMessageType.info => const Duration(seconds: 4),
        AppMessageType.warning => const Duration(seconds: 5),
        AppMessageType.error => const Duration(seconds: 6),
        AppMessageType.loading => const Duration(days: 1), // hasta que se cierre
      };

  /// La operación terminó correctamente.
  static void success(String title, {String? message}) =>
      show(title, message: message, type: AppMessageType.success);

  /// Falló algo. `title` debe ser comprensible: nunca un error técnico.
  static void error(String title, {String? message}) =>
      show(title, message: message, type: AppMessageType.error);

  static void warning(String title, {String? message}) =>
      show(title, message: message, type: AppMessageType.warning);

  static void info(String title, {String? message}) =>
      show(title, message: message, type: AppMessageType.info);

  /// Se guardó en el dispositivo pero NO lo confirmó el servidor.
  /// Es un caso aparte de [success] a propósito, para no afirmar de más.
  static void pending(String title, {String? message}) => show(
        title,
        message: message ?? 'Quedó guardado en el dispositivo, pendiente de sincronizar.',
        type: AppMessageType.info,
      );

  /// Muestra una operación en curso. Cerrar con `.close()`.
  static AppMessageHandle loading(String title, {String? message}) {
    show(title, message: message, type: AppMessageType.loading, allowRepeat: true);
    return const AppMessageHandle();
  }

  /// Cierra el mensaje visible, si lo hay.
  static void dismiss() => key.currentState?.hideCurrentSnackBar();

  static void show(
    String title, {
    String? message,
    AppMessageType type = AppMessageType.info,
    bool allowRepeat = false,
  }) {
    final messenger = key.currentState;
    if (messenger == null) return; // la app todavía no está montada

    final signature = '${type.name}|$title|${message ?? ''}';
    final now = DateTime.now();
    if (!allowRepeat &&
        _lastSignature == signature &&
        _lastShownAt != null &&
        now.difference(_lastShownAt!) < _dedupeWindow) {
      return; // mensaje duplicado: no se repite
    }
    _lastSignature = signature;
    _lastShownAt = now;

    final dismissible = type == AppMessageType.error || type == AppMessageType.warning;

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          duration: _durationFor(type),
          dismissDirection: DismissDirection.horizontal,
          padding: EdgeInsets.zero,
          margin: const EdgeInsets.all(AppSpacing.md),
          content: AppMessageCard(
            title: title,
            message: message,
            type: type,
            onClose: dismissible ? dismiss : null,
          ),
        ),
      );
  }
}

/// Control de un mensaje de carga.
class AppMessageHandle {
  const AppMessageHandle();

  void close() => AppMessenger.dismiss();

  /// Cierra la carga y muestra el resultado real de la operación.
  void finishSuccess(String title, {String? message}) {
    AppMessenger.dismiss();
    AppMessenger.success(title, message: message);
  }

  void finishError(String title, {String? message}) {
    AppMessenger.dismiss();
    AppMessenger.error(title, message: message);
  }

  /// Terminó, pero el servidor todavía no lo confirmó.
  void finishPending(String title, {String? message}) {
    AppMessenger.dismiss();
    AppMessenger.pending(title, message: message);
  }
}

/// Tarjeta visual del mensaje. Usa los tokens del sistema de diseño.
class AppMessageCard extends StatelessWidget {
  const AppMessageCard({super.key, required this.title, this.message, required this.type, this.onClose});

  final String title;
  final String? message;
  final AppMessageType type;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color border, Color fg, IconData? icon) = switch (type) {
      AppMessageType.success => (AppColors.primaryLight, AppColors.successBorder, AppColors.primaryDark, Icons.check_circle_outline),
      AppMessageType.error => (AppColors.errorLight, AppColors.errorBorder, AppColors.error, Icons.error_outline),
      AppMessageType.warning => (AppColors.warningLight, AppColors.warningBorder, AppColors.warningText, Icons.warning_amber_rounded),
      AppMessageType.info => (AppColors.infoLight, AppColors.infoBorder, AppColors.info, Icons.info_outline),
      AppMessageType.loading => (AppColors.infoLight, AppColors.infoBorder, AppColors.info, null),
    };

    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: border),
          boxShadow: AppShadows.raised,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null)
              Icon(icon, size: AppIconSize.md, color: fg)
            else
              SizedBox(
                width: AppIconSize.md,
                height: AppIconSize.md,
                child: CircularProgressIndicator(strokeWidth: 2.2, color: fg),
              ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.bodySmStrong.copyWith(color: AppColors.textPrimary)),
                  if (message != null) ...[
                    const SizedBox(height: 2),
                    Text(message!, style: AppText.caption.copyWith(color: fg)),
                  ],
                ],
              ),
            ),
            if (onClose != null)
              InkWell(
                onTap: onClose,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                child: Tooltip(
                  message: 'Cerrar',
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(Icons.close, size: 18, color: fg),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
