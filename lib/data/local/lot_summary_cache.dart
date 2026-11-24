import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Copia guardada de un resumen de lote, con la fecha en que se obtuvo.
class CachedLotSummary {
  const CachedLotSummary(this.datos, this.guardadoEn);

  /// Respuesta de `GET /lotes/{id}/resumen` tal como llegó del servidor.
  final Map<String, dynamic> datos;
  final DateTime guardadoEn;
}

/// Última respuesta de `GET /lotes/{id}/resumen` por usuario y lote, guardada en el teléfono
/// para mostrarla cuando no hay red.
///
/// Se guarda el JSON del servidor sin transformar (todo lo calcula el backend). Cada copia
/// pertenece a un usuario: otra cuenta en el mismo teléfono no ve los lotes de quien la usó.
class LotSummaryCache {
  static const _clave = 'sigat.resumen_lote.v1';

  /// Guarda o reemplaza la copia de [lotId] para [dueno]. Un fallo al guardar no debe
  /// romper la pantalla: sin caché solo se pierde el respaldo sin conexión.
  Future<void> save(
      String dueno, String lotId, Map<String, dynamic> datos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todos = _leer(prefs);
      todos[_llave(dueno, lotId)] = {
        'guardado_en': DateTime.now().toIso8601String(),
        'datos': datos,
      };
      await prefs.setString(_clave, jsonEncode(todos));
    } catch (_) {
      // Sin caché no hay respaldo offline, pero la consulta en línea ya funcionó.
    }
  }

  /// Copia de [lotId] para [dueno], o null si no existe o está dañada.
  Future<CachedLotSummary?> read(String dueno, String lotId) async {
    final prefs = await SharedPreferences.getInstance();
    final entrada = _leer(prefs)[_llave(dueno, lotId)];
    if (entrada is! Map) return null;
    final fecha = DateTime.tryParse('${entrada['guardado_en']}');
    final datos = entrada['datos'];
    if (fecha == null || datos is! Map) return null;
    return CachedLotSummary(Map<String, dynamic>.from(datos), fecha.toLocal());
  }

  static String _llave(String dueno, String lotId) => '$dueno|$lotId';

  /// Un valor dañado se descarta: la caché se reconstruye con la siguiente consulta en línea.
  static Map<String, dynamic> _leer(SharedPreferences prefs) {
    final texto = prefs.getString(_clave);
    if (texto == null || texto.isEmpty) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(texto) as Map);
    } catch (_) {
      return {};
    }
  }
}
