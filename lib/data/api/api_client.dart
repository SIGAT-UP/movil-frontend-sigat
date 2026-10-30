import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import 'secure_store.dart';

/// Error del backend (`application/problem+json`) o de la red, con un texto listo
/// para mostrar. [code] es el `codigo` estable del backend (p. ej. `CREDENCIALES_INVALIDAS`).
class ApiException implements Exception {
  const ApiException(this.status, this.title, this.detail, {this.code});

  /// 0 = sin conexión o tiempo agotado.
  final int status;
  final String title;
  final String detail;
  final String? code;

  bool get isNetwork => status == 0;

  /// La ruta existe en el contrato del backend pero todavía no está programada (501).
  bool get isNotImplemented => status == 501;

  @override
  String toString() => 'ApiException($status, $code)';
}

/// Cliente HTTP único para `sigat-durazno-api`.
///
/// * Agrega `Authorization: Bearer <token>` y `X-App-Version`.
/// * Ante un 401 renueva UNA vez el token con `POST /auth/refresco` y repite la petición.
/// * Convierte los errores en [ApiException] (nunca deja pasar un error de red crudo).
class ApiClient {
  ApiClient({http.Client? client, SecureStore? store, String? baseUrl})
      : _http = client ?? http.Client(),
        store = store ?? SecureStore(),
        _base = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _http;
  final SecureStore store;
  final String _base;
  Future<bool>? _renovando;

  Uri uri(String path, [Map<String, Object?>? query]) {
    final u = Uri.parse('$_base$path');
    final q = <String, String>{
      for (final e in (query ?? const <String, Object?>{}).entries)
        if (e.value != null) e.key: e.value.toString(),
    };
    return q.isEmpty ? u : u.replace(queryParameters: {...u.queryParameters, ...q});
  }

  /// Respuesta que es un objeto JSON.
  Future<Map<String, dynamic>?> get(String path, {Map<String, Object?>? query}) async {
    final r = await _send('GET', path, query: query);
    return r is Map<String, dynamic> ? r : null;
  }

  /// Respuesta que es una lista JSON (p. ej. `GET /yo/predios`).
  Future<List<Map<String, dynamic>>> getList(String path, {Map<String, Object?>? query}) async {
    final r = await _send('GET', path, query: query);
    if (r is! List) return const [];
    return [for (final x in r) if (x is Map<String, dynamic>) x];
  }

  /// [auth] = false para las rutas públicas (login, recuperación).
  Future<Map<String, dynamic>?> post(String path, {Object? body, bool auth = true}) async {
    final r = await _send('POST', path, body: body, auth: auth);
    return r is Map<String, dynamic> ? r : null;
  }

  Future<Map<String, dynamic>?> put(String path, {Object? body}) async {
    final r = await _send('PUT', path, body: body);
    return r is Map<String, dynamic> ? r : null;
  }

  Future<Object?> _send(
    String method,
    String path, {
    Object? body,
    Map<String, Object?>? query,
    bool auth = true,
    bool reintento = false,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'X-App-Version': ApiConfig.appVersion,
      if (body != null) 'Content-Type': 'application/json',
    };
    final token = auth ? await store.accessToken : null;
    if (token != null) headers['Authorization'] = 'Bearer $token';

    // SEGURIDAD: sin redirecciones automáticas. Una redirección podría reenviar el token Bearer a
    // otro servidor; la API no redirige, así que un 3xx se trata como error.
    final request = http.Request(method, uri(path, query))
      ..followRedirects = false
      ..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);

    final http.Response res;
    try {
      res = await http.Response.fromStream(await _http.send(request).timeout(ApiConfig.timeout));
    } on TimeoutException {
      throw const ApiException(
        0,
        'Sin respuesta del servidor',
        'El servidor tardó demasiado en responder. Intente de nuevo.',
      );
    } catch (_) {
      throw const ApiException(
        0,
        'Sin conexión',
        'No hay conexión con el servidor. Revise su conexión e intente de nuevo.',
      );
    }

    if (res.statusCode == 401 && token != null && !reintento && await _renovar()) {
      return _send(method, path, body: body, query: query, auth: auth, reintento: true);
    }
    final data = _decode(res);
    if (res.statusCode >= 200 && res.statusCode < 300) return data;
    throw _error(res.statusCode, data is Map<String, dynamic> ? data : null);
  }

  /// Una sola renovación a la vez aunque fallen varias peticiones juntas.
  Future<bool> _renovar() {
    final enCurso = _renovando;
    if (enCurso != null) return enCurso;
    final nueva = _renovarAhora();
    _renovando = nueva;
    nueva.whenComplete(() => _renovando = null);
    return nueva;
  }

  Future<bool> _renovarAhora() async {
    try {
      final refresco = await store.refreshToken;
      if (refresco == null) return false;
      final peticion = http.Request('POST', uri('/auth/refresco'))
        ..followRedirects = false
        ..headers.addAll({'Content-Type': 'application/json', 'Accept': 'application/json'})
        ..body = jsonEncode({'token_refresco': refresco});
      final res = await http.Response.fromStream(await _http.send(peticion).timeout(ApiConfig.timeout));
      final data = _json(res);
      if (res.statusCode != 200 || data == null || data['token'] is! String) {
        await store.clearTokens();
        return false;
      }
      await store.saveTokens(access: data['token'] as String, refresh: data['token_refresco'] as String?);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// El cuerpo se decodifica siempre como UTF-8 (tildes y eñes de los mensajes).
  static Object? _decode(http.Response res) {
    if (res.bodyBytes.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic>? _json(http.Response res) {
    final valor = _decode(res);
    return valor is Map<String, dynamic> ? valor : null;
  }

  static ApiException _error(int status, Map<String, dynamic>? d) {
    final detail = d?['detail'];
    final title = d?['title'];
    final code = d?['codigo'];
    return ApiException(
      status,
      title is String ? title : 'No se pudo completar la solicitud',
      detail is String ? detail : _mensajePorEstado(status),
      code: code is String ? code : null,
    );
  }

  static String _mensajePorEstado(int status) {
    if (status == 401) return 'Su sesión terminó. Inicie sesión de nuevo.';
    if (status == 403) return 'No tiene permiso para realizar esta acción.';
    if (status == 404) return 'No se encontró la información solicitada.';
    if (status == 429) return 'Demasiados intentos. Espere unos minutos e intente de nuevo.';
    if (status == 501) return 'Esta función todavía no está disponible en el servidor.';
    if (status >= 500) return 'El servidor tuvo un problema. Intente de nuevo en unos minutos.';
    return 'No se pudo completar la solicitud.';
  }
}
