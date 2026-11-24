import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/mapa_predio.dart';
import '../models/paquete_campo.dart';

/// Paquete de campo guardado en el teléfono, con la versión y el hash con que se descargó.
class PaqueteLocal {
  const PaqueteLocal({
    required this.version,
    required this.hash,
    required this.etag,
    required this.guardadoEn,
    required this.contenido,
  });

  final int version;
  final String hash;

  /// Valor de `ETag` para `If-None-Match` (con comillas).
  final String etag;
  final DateTime guardadoEn;

  /// Respuesta de `/paquete-campo/contenido` tal como llegó, sin interpretar.
  final Map<String, dynamic> contenido;

  /// Capas del predio (predio, lotes, celdas y trampas) para MapLibre.
  MapaPredio get mapa =>
      MapaPredio.fromJson(Map<String, dynamic>.from(contenido['mapa'] as Map));

  /// ¿Esta copia sigue siendo la versión vigente que informa el servidor?
  bool coincide(PaqueteCampo info) =>
      info.vigente && info.version == version && info.hash == hash;
}

/// Un paquete por predio en `SharedPreferences`, con clave versionada `sigat.paquete.v1.<predioId>`.
/// Guardar reemplaza el anterior; borrar lo quita cuando el servidor lo invalidó.
class PaqueteCampoStore {
  static const _prefijo = 'sigat.paquete.v1.';

  Future<PaqueteLocal?> leer(String predioId) async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString('$_prefijo$predioId');
    if (texto == null || texto.isEmpty) return null;
    try {
      final j = jsonDecode(texto) as Map<String, dynamic>;
      return PaqueteLocal(
        version: j['version'] as int,
        hash: j['hash'] as String,
        etag: j['etag'] as String,
        guardadoEn: DateTime.parse(j['guardado_en'] as String),
        contenido: Map<String, dynamic>.from(j['contenido'] as Map),
      );
    } catch (_) {
      // Un paquete dañado se descarta: se vuelve a bajar con la siguiente descarga.
      await prefs.remove('$_prefijo$predioId');
      return null;
    }
  }

  Future<void> guardar(String predioId, PaqueteLocal paquete) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefijo$predioId',
      jsonEncode({
        'version': paquete.version,
        'hash': paquete.hash,
        'etag': paquete.etag,
        'guardado_en': paquete.guardadoEn.toIso8601String(),
        'contenido': paquete.contenido,
      }),
    );
  }

  Future<void> borrar(String predioId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefijo$predioId');
  }
}
