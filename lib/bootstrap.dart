/// Arranque de la aplicación.
///
/// Aquí se inicializan la base local (SQLite espacial), la cola de envío y la
/// configuración regional antes de montar la interfaz. Por ahora solo monta la
/// pantalla inicial.
library;

import 'package:flutter/material.dart';

import 'app/app.dart';

void bootstrap() {
  runApp(const SigatApp());
}
