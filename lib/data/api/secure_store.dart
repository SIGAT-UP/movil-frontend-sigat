import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Datos sensibles de la sesión, en el almacenamiento SEGURO del sistema
/// (Keystore en Android, Keychain en iOS). Nunca en la base local ni en un log
/// (SEGURIDAD S-09 y S-10).
///
/// * Token de acceso: JWT corto (15 min) que va en `Authorization: Bearer`.
/// * Token de refresco: renueva el de acceso sin pedir la contraseña.
/// * `disp_id`: dispositivo registrado por el backend; se reenvía al iniciar sesión
///   y lo usará la sincronización.
/// * Usuario recordado: solo si la persona marcó «Recordar usuario».
class SecureStore {
  SecureStore({FlutterSecureStorage? storage}) : _s = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _s;

  static const _kAcceso = 'sigat.token_acceso';
  static const _kRefresco = 'sigat.token_refresco';
  static const _kDispositivo = 'sigat.disp_id';
  static const _kUsuarioRecordado = 'sigat.usuario_recordado';
  static const _kSesion = 'sigat.sesion';

  Future<String?> get accessToken => _leer(_kAcceso);
  Future<String?> get refreshToken => _leer(_kRefresco);
  Future<String?> get deviceId => _leer(_kDispositivo);
  Future<String?> get rememberedUser => _leer(_kUsuarioRecordado);

  /// Datos de la última sesión (SIN tokens): nombre, rol… para abrir la app sin conexión.
  Future<String?> get sessionUser => _leer(_kSesion);
  Future<void> saveSessionUser(String json) => _escribir(_kSesion, json);

  Future<void> saveTokens({required String access, String? refresh}) async {
    await _escribir(_kAcceso, access);
    if (refresh != null) await _escribir(_kRefresco, refresh);
  }

  Future<void> saveDeviceId(String id) => _escribir(_kDispositivo, id);

  Future<void> saveRememberedUser(String? usuario) =>
      usuario == null ? _borrar(_kUsuarioRecordado) : _escribir(_kUsuarioRecordado, usuario);

  /// Cierre de sesión: borra los tokens y la sesión guardada. El dispositivo y el usuario
  /// recordado se conservan.
  Future<void> clearTokens() async {
    await _borrar(_kAcceso);
    await _borrar(_kRefresco);
    await _borrar(_kSesion);
  }

  // Si el almacenamiento seguro no está disponible (p. ej. en pruebas), la app sigue:
  // simplemente no recuerda nada entre aperturas.
  Future<String?> _leer(String clave) async {
    try {
      return await _s.read(key: clave);
    } catch (_) {
      return null;
    }
  }

  Future<void> _escribir(String clave, String valor) async {
    try {
      await _s.write(key: clave, value: valor);
    } catch (_) {
      // Sin almacenamiento seguro: la sesión dura solo mientras la app esté abierta.
    }
  }

  Future<void> _borrar(String clave) async {
    try {
      await _s.delete(key: clave);
    } catch (_) {
      // Nada que borrar o almacenamiento no disponible.
    }
  }
}
