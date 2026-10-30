import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/config/api_config.dart';
import '../api/api_client.dart';
import '../models/user_session.dart';
import 'auth_repository.dart';

/// Inicio de sesión REAL contra `sigat-durazno-api` (BD SIGAT v9).
///
///   POST /auth/login  {usuario, contrasena, cliente: "movil", recordar, dispositivo}
///   → {token, token_refresco, disp_id, user: {id, nombre, usuario, rol, …}}
///
/// Los tokens y el `disp_id` quedan en el almacenamiento seguro ([ApiClient.store]).
/// El backend decide qué mensaje mostrar (credenciales, cuenta incompleta, bloqueo por
/// intentos…); aquí solo se pasa a [AuthException] para la caja roja del login.
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository({ApiClient? client}) : _api = client ?? ApiClient();

  final ApiClient _api;

  @override
  Future<UserSession> login({required String username, required String password, required bool remember}) async {
    final disp = await _api.store.deviceId;
    final Map<String, dynamic>? r;
    try {
      r = await _api.post(
        '/auth/login',
        auth: false,
        body: {
          'usuario': username.trim(),
          'contrasena': password,
          'cliente': 'movil',
          'recordar': remember,
          'dispositivo': {
            if (disp != null) 'disp_id': disp,
            'plataforma': _plataforma(),
            'version_app': ApiConfig.appVersion,
          },
        },
      );
    } on ApiException catch (e) {
      throw AuthException(_titulo(e), e.detail);
    }

    if (r == null || r['token'] is! String || r['user'] is! Map<String, dynamic>) {
      throw const AuthException('No pudimos iniciar sesión', 'El servidor no devolvió una sesión válida.');
    }
    final session = UserSession.fromApi(r);
    if (session.role == UserRole.desconocido) {
      // S-01: un rol que esta versión no conoce no abre ninguna pantalla.
      throw const AuthException(
        'Rol no reconocido',
        'Su cuenta tiene un rol que esta versión de la app no conoce. Actualice la app o contacte al administrador.',
      );
    }
    await _api.store.saveTokens(access: r['token'] as String, refresh: r['token_refresco'] as String?);
    final dispId = r['disp_id'];
    if (dispId is String) await _api.store.saveDeviceId(dispId);
    await _api.store.saveRememberedUser(remember ? username.trim() : null);
    await _api.store.saveSessionUser(jsonEncode(session.toJson()));
    return session;
  }

  /// `GET /auth/sesion` con el token guardado (si venció, [ApiClient] lo renueva con el
  /// de refresco). Sin conexión se abre la última sesión conocida: el técnico trabaja en
  /// campo y lo que registre queda en el teléfono hasta que haya red.
  @override
  Future<UserSession?> restoreSession() async {
    if (await _api.store.refreshToken == null && await _api.store.accessToken == null) return null;
    try {
      final r = await _api.get('/auth/sesion');
      if (r == null) return null;
      final session = UserSession.fromApi({'token': await _api.store.accessToken ?? '', 'user': r});
      if (session.role == UserRole.desconocido) return null;
      await _api.store.saveSessionUser(jsonEncode(session.toJson()));
      return session;
    } on ApiException catch (e) {
      if (e.isNetwork) {
        final guardada = await _api.store.sessionUser;
        if (guardada == null) return null;
        try {
          final s = UserSession.fromJson(jsonDecode(guardada) as Map<String, dynamic>);
          return s.role == UserRole.desconocido ? null : s;
        } catch (_) {
          return null;
        }
      }
      // 401/403: la sesión se cerró, venció o la cuenta cambió → pedir login.
      await _api.store.clearTokens();
      return null;
    }
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    try {
      await _api.post('/auth/recuperacion', auth: false, body: {'identificador': email.trim()});
    } on ApiException catch (e) {
      throw AuthException(_titulo(e), e.detail);
    }
  }

  @override
  Future<String?> getRememberedUser() => _api.store.rememberedUser;

  @override
  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (_) {
      // Sin red o con la sesión ya vencida, la sesión se cierra igual en el dispositivo.
    } finally {
      await _api.store.clearTokens();
    }
  }

  static String _titulo(ApiException e) {
    if (e.isNetwork) return e.title;
    return switch (e.code) {
      'LOGIN_BLOQUEADO' => 'Demasiados intentos',
      'ROL_SOLO_MOVIL' || 'CUENTA_INCOMPLETA' || 'REQUIERE_RESTABLECER' => 'No se puede ingresar',
      'USAR_PROVEEDOR_INSTITUCIONAL' => 'Ingreso institucional',
      _ => 'No pudimos iniciar sesión',
    };
  }

  /// Plataforma que guarda la tabla `dispositivo` (android | ios | otro).
  static String _plataforma() {
    if (kIsWeb) return 'otro';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      _ => 'otro',
    };
  }
}
