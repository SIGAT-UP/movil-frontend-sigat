import 'package:flutter/material.dart';

import 'theme/app_theme.dart';

/// Raíz de la aplicación.
///
/// Cuando exista el router (go_router) y el contenedor de estado (Riverpod),
/// este widget solo compondrá providers y `MaterialApp.router`.
class SigatApp extends StatelessWidget {
  const SigatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIGAT · Durazno',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _InicioPage(),
    );
  }
}

class _InicioPage extends StatelessWidget {
  const _InicioPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SIGAT · Durazno')),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monitoreo fitosanitario',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Aplicación en construcción. Capture visitas y lecturas en campo.'),
          ],
        ),
      ),
    );
  }
}
