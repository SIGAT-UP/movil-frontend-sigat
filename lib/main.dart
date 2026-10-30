import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/config_error_app.dart';
import 'core/config/api_config.dart';
import 'data/connectivity_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // SEGURIDAD: una compilación de producción sin API_URL HTTPS no arranca contra ningún servidor.
  final problema = ApiConfig.problemaDeConfiguracion;
  if (problema != null) {
    runApp(ConfigErrorApp(mensaje: problema));
    return;
  }
  // Estado real de conexión (Wi-Fi / datos / sin red) antes de pintar la primera pantalla.
  await ConnectivityService.instance.init();
  // Todo va contra sigat-durazno-api (URL por entorno en lib/core/config/api_config.dart).
  // Los tokens quedan en el almacenamiento seguro del sistema y lo capturado sin conexión,
  // en la cola local de pendientes (lib/data/local/pending_store.dart).
  runApp(const VigilanciaDuraznoApp());
}
