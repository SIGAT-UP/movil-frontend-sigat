import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';
import '../../data/repositories/field_repositories.dart';

/// Estado de error de una carga, con el motivo REAL:
///
/// * [OfflineException] → «Sin conexión»: lo guardado en el teléfono sigue a salvo.
/// * [NotAvailableYet] → la función existe en la app pero el servidor aún no la ofrece (501).
/// * Otro error → el mensaje del servidor, si lo hay.
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.error, this.onRetry, this.what = 'la información'});

  final Object? error;
  final VoidCallback? onRetry;

  /// Qué se intentaba cargar («tus lotes», «el resumen del lote»…).
  final String what;

  @override
  Widget build(BuildContext context) {
    final e = error;
    final (icon, title) = switch (e) {
      OfflineException() => (Icons.cloud_off, 'Sin conexión'),
      NotAvailableYet() => (Icons.construction_outlined, 'Aún no disponible'),
      _ => (Icons.error_outline, 'No se pudo cargar $what'),
    };
    return EmptyState(
      icon: icon,
      title: title,
      message: e is DataException ? e.message : 'Intenta de nuevo en unos minutos.',
      action: onRetry == null ? null : SecondaryButton(label: 'Reintentar', onPressed: onRetry!),
    );
  }
}

/// Cuerpo de un [FutureBuilder] con los cuatro estados: cargando, error, vacío y datos.
///
///     FutureBuilder<List<Lot>>(
///       future: _future,
///       builder: (context, snap) => AsyncBody(
///         snapshot: snap, what: 'tus lotes', onRetry: _reload,
///         isEmpty: (l) => l.isEmpty,
///         empty: const EmptyState(icon: Icons.inbox_outlined, title: 'Sin lotes'),
///         builder: (lots) => ListView(...),
///       ),
///     )
class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({
    super.key,
    required this.snapshot,
    required this.builder,
    this.onRetry,
    this.what = 'la información',
    this.isEmpty,
    this.empty,
  });

  final AsyncSnapshot<T> snapshot;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;
  final String what;
  final bool Function(T data)? isEmpty;
  final Widget? empty;

  @override
  Widget build(BuildContext context) {
    if (snapshot.hasError) return ErrorState(error: snapshot.error, onRetry: onRetry, what: what);
    if (snapshot.connectionState != ConnectionState.done || !snapshot.hasData) {
      if (snapshot.connectionState == ConnectionState.done && null is T) return builder(snapshot.data as T);
      return const AppLoader();
    }
    final data = snapshot.data as T;
    if (empty != null && (isEmpty?.call(data) ?? false)) return empty!;
    return builder(data);
  }
}
