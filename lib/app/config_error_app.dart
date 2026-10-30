import 'package:flutter/material.dart';

/// Pantalla que se muestra en lugar de la app cuando la compilación de producción no tiene una
/// dirección segura del servidor (ver `ApiConfig.problemaDeConfiguracion`). No hace peticiones.
class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({super.key, required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'SIGAT',
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.settings_suggest_outlined, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'SIGAT no está configurado',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(mensaje),
                  const SizedBox(height: 8),
                  const Text('Contacte al administrador del sistema.'),
                ],
              ),
            ),
          ),
        ),
      );
}
