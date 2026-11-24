import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Copia guardada del detalle de una visita, con la fecha en que se obtuvo.
class CachedVisit {
  const CachedVisit(this.datos, this.guardadoEn);

  /// Respuesta de `GET /visitas/{id}` tal como llegó del servidor.
  final Map<String, dynamic> datos;
  final DateTime guardadoEn;
}

/// Último detalle de cada visita por usuario, guardado en el teléfono para cuando no hay red.
///
/// Mismo patrón que `LotSummaryCache`: JSON en `SharedPreferences` con clave versionada.
/// Cada copia pertenece a un usuario; otra cuenta en el mismo teléfono no la ve.
class VisitDetailCache {
  static const _clave = 'sigat.detalle_visita.v1';

  /// Guarda o reemplaza la copia de [visitId] para [dueno]. Un fallo al guardar no rompe la
  /// pantalla: sin caché solo se pierde el respaldo sin conexión.
  Future<void> save(
      String dueno, String visitId, Map<String, dynamic> datos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todos = _leer(prefs);
      todos[_llave(dueno, visitId)] = {
        'guardado_en': DateTime.now().toIso8601String(),
        'datos': datos,
      };
      await prefs.setString(_clave, jsonEncode(todos));
    } catch (_) {
      // Sin caché no hay respaldo offline, pero la consulta en línea ya funcionó.
    }
  }

  /// Copia de [visitId] para [dueno], o null si no existe o está dañada.
  Future<CachedVisit?> read(String dueno, String visitId) async {
    final prefs = await SharedPreferences.getInstance();
    final entrada = _leer(prefs)[_llave(dueno, visitId)];
    if (entrada is! Map) return null;
    final fecha = DateTime.tryParse('${entrada['guardado_en']}');
    final datos = entrada['datos'];
    if (fecha == null || datos is! Map) return null;
    return CachedVisit(Map<String, dynamic>.from(datos), fecha.toLocal());
  }

  static String _llave(String dueno, String visitId) => '$dueno|$visitId';

  /// Un valor dañado se descarta; la caché se reconstruye con la siguiente consulta en línea.
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
