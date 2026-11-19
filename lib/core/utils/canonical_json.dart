import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class CanonicalJson {
  CanonicalJson._();

  static String serialize(Object? value) {
    final salida = StringBuffer();
    _escribir(value, salida);
    return salida.toString();
  }

  static String sha256Hex(Object? value) {
    final bytes = utf8.encode(serialize(value));
    return sha256.convert(bytes).toString();
  }

  static String instanteCanonico(DateTime valor) {
    final u = valor.toUtc();
    final anio = u.year.toString().padLeft(4, '0');
    final mes = u.month.toString().padLeft(2, '0');
    final dia = u.day.toString().padLeft(2, '0');
    final hora = u.hour.toString().padLeft(2, '0');
    final minuto = u.minute.toString().padLeft(2, '0');
    final segundo = u.second.toString().padLeft(2, '0');
    final milisegundo = u.millisecond.toString().padLeft(3, '0');
    return '$anio-$mes-$dia' 'T$hora:$minuto:$segundo.${milisegundo}Z';
  }

  static String generarUuidV4() {
    final azar = Random.secure();
    final bytes = List<int>.generate(16, (_) => azar.nextInt(256));
    _marcarUuid(bytes, version: 4);
    return _formatearUuid(bytes);
  }

  static String uuidDesdeSemilla(String semilla) {
    final bytes = sha256.convert(utf8.encode(semilla)).bytes.sublist(0, 16);
    _marcarUuid(bytes, version: 5);
    return _formatearUuid(bytes);
  }

  static void _marcarUuid(List<int> bytes, {required int version}) {
    bytes[6] = (bytes[6] & 0x0f) | (version << 4);
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
  }

  static String _formatearUuid(List<int> bytes) {
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  static void _escribir(Object? valor, StringBuffer salida) {
    if (valor == null) {
      salida.write('null');
    } else if (valor is bool) {
      salida.write(valor ? 'true' : 'false');
    } else if (valor is num) {
      salida.write(_numero(valor));
    } else if (valor is String) {
      salida.write(jsonEncode(valor));
    } else if (valor is List) {
      salida.write('[');
      for (var i = 0; i < valor.length; i++) {
        if (i > 0) salida.write(',');
        _escribir(valor[i], salida);
      }
      salida.write(']');
    } else if (valor is Map) {
      final claves = valor.keys.map(_claveTexto).toList()..sort();
      salida.write('{');
      for (var i = 0; i < claves.length; i++) {
        if (i > 0) salida.write(',');
        salida.write(jsonEncode(claves[i]));
        salida.write(':');
        _escribir(valor[claves[i]], salida);
      }
      salida.write('}');
    } else {
      throw ArgumentError.value(
          valor, 'valor', 'Tipo no serializable en JSON canónico.');
    }
  }

  static String _claveTexto(Object? clave) {
    if (clave is String) return clave;
    throw ArgumentError.value(
        clave, 'clave', 'Las claves del JSON canónico deben ser texto.');
  }

  static String _numero(num valor) {
    if (valor is int) return valor.toString();
    final doble = valor.toDouble();
    if (doble.isNaN || doble.isInfinite) {
      throw ArgumentError.value(
          valor, 'valor', 'NaN e Infinity no existen en JSON.');
    }
    if (doble == 0) return '0';
    final texto = doble.toString();
    return texto.endsWith('.0') ? texto.substring(0, texto.length - 2) : texto;
  }
}
