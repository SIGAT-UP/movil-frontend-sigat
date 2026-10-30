/// Roles definidos en el levantamiento de requerimientos.
///
/// [desconocido] NO es un rol del negocio: es el valor seguro cuando el
/// servidor envía un rol que esta versión de la app no conoce. Antes se caía
/// en `tecnico` por defecto, lo que daba acceso a registrar lecturas a
/// cualquier cuenta con un rol mal escrito o nuevo.
enum UserRole {
  agronomo('Agrónomo'),
  tecnico('Técnico'),
  coordinador('Coordinador'),
  productor('Productor'),
  administrador('Administrador'),
  desconocido('Sin rol reconocido');

  const UserRole(this.label);
  final String label;

  /// Convierte el rol que envía el servidor. Si no se reconoce, devuelve
  /// [desconocido] y la app no abre las pantallas de ningún rol.
  /// Acepta el nombre interno de la app (`tecnico`) y los códigos de la BD
  /// (`rol.rol_codigo`): ADMINISTRADOR, AGRONOMO_SUPERVISOR, TECNICO, PRODUCTOR.
  /// `coordinador` no existe en la BD v7: queda solo por compatibilidad.
  static UserRole fromString(String? v) {
    if (v == null) return desconocido;
    final key = v.trim().toLowerCase();
    if (key == 'agronomo_supervisor' || key == 'supervisor') return agronomo;
    for (final r in values) {
      if (r != desconocido && r.name == key) return r;
    }
    return desconocido;
  }
}

/// Sesión del usuario autenticado.
///
/// SEGURIDAD: el `token` no se incluye en [toJson] a propósito, para que no
/// termine por accidente en la base local, en un archivo de registro ni en un
/// reporte de errores. Cuando se implemente la persistencia de sesión, el
/// token debe guardarse aparte con `flutter_secure_storage`
/// (Keystore en Android / Keychain en iOS) usando [tokenForSecureStorage].
class UserSession {
  const UserSession({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.shortName,
    required this.role,
    required this.scope,
    required this.device,
    required String token,
  }) : _token = token;

  final String userId;
  final String username; // correo o usuario
  final String displayName; // Nombre de la persona
  final String shortName; // Nombre abreviado
  final UserRole role;
  final String scope; //  Lote asignado
  final String device; // "Móvil"

  final String _token;

  /// Único acceso al token. El nombre deja claro dónde debe guardarse.
  String get tokenForSecureStorage => _token;

  bool get hasToken => _token.isNotEmpty;

  String get firstName => displayName.split(' ').first;

  factory UserSession.fromJson(Map<String, dynamic> j) => UserSession(
        userId: j['user_id'].toString(),
        username: j['username'] as String,
        displayName: j['display_name'] as String,
        shortName: j['short_name'] as String? ?? j['display_name'] as String,
        role: UserRole.fromString(j['role'] as String?),
        scope: j['scope'] as String? ?? '',
        device: j['device'] as String? ?? 'Móvil',
        token: j['token'] as String? ?? '',
      );

  /// Construye la sesión desde la respuesta de `POST /auth/login`:
  /// `{ token, user: { id, rol, nombre, usuario } }`.
  factory UserSession.fromApi(Map<String, dynamic> j) {
    final u = j['user'] as Map<String, dynamic>;
    final nombre = (u['nombre'] as String).trim();
    final partes = nombre.split(RegExp(r'\s+'));
    final corto = partes.length > 1 ? '${partes.first[0]}. ${partes.last}' : nombre;
    return UserSession(
      userId: u['id'].toString(),
      username: u['usuario'] as String,
      displayName: nombre,
      shortName: corto,
      role: UserRole.fromString(u['rol'] as String?),
      scope: '',
      device: 'Móvil',
      token: j['token'] as String? ?? '',
    );
  }

  /// Datos del usuario SIN el token. Apto para guardar en la base local.
  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'username': username,
        'display_name': displayName,
        'short_name': shortName,
        'role': role.name,
        'scope': scope,
        'device': device,
      };

  /// Evita que el token aparezca al imprimir el objeto en un log.
  @override
  String toString() => 'UserSession($userId, ${role.name})';
}
