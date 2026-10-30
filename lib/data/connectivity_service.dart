import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'app_services.dart';

/// Detecta el estado REAL de la conexión y lo publica en [AppServices.isOnline].
/// Toda la interfaz (chips "Conectado / Sin conexión", avisos, botones de
/// sincronizar y descargar mapa) escucha ese valor, así que se actualiza sola.
///
/// Funciona en Android, iOS y web (en web usa `navigator.onLine`).
///
/// Importante: tener Wi-Fi o datos no garantiza llegar a internet (ej. Wi-Fi con
/// portal cautivo). Cuando exista el backend, asigna [reachability] para hacer
/// una verificación real, por ejemplo:
///   ConnectivityService.instance.reachability = () => api.ping(); // GET /health
class ConnectivityService {
  ConnectivityService._();
  static final instance = ConnectivityService._();

  final _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;

  /// Verificación opcional de alcance real al servidor. Si es null, basta con tener red.
  Future<bool> Function()? reachability;

  /// Llamar una vez al iniciar la app (main.dart).
  Future<void> init() async {
    try {
      await _apply(await _connectivity.checkConnectivity());
    } catch (_) {
      // Si la plataforma no responde, se asume conectado y los errores de red se manejan en cada llamada.
    }
    _sub ??= _connectivity.onConnectivityChanged.listen(_apply);
  }

  /// Vuelve a verificar (ej. antes de sincronizar o al tocar "Reintentar").
  Future<bool> refresh() async {
    try {
      await _apply(await _connectivity.checkConnectivity());
    } catch (_) {}
    return AppServices.isOnline.value;
  }

  Future<void> _apply(List<ConnectivityResult> results) async {
    final hasNetwork = results.any((r) => r != ConnectivityResult.none);
    var online = hasNetwork;
    final check = reachability;
    if (hasNetwork && check != null) {
      try {
        online = await check().timeout(const Duration(seconds: 5));
      } catch (_) {
        online = false;
      }
    }
    if (AppServices.isOnline.value != online) AppServices.isOnline.value = online;
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }
}
