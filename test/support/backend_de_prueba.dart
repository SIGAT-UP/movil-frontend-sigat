import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vigilancia_durazno/core/utils/canonical_json.dart';
import 'package:vigilancia_durazno/data/api/api_client.dart';
import 'package:vigilancia_durazno/data/api/secure_store.dart';
import 'package:vigilancia_durazno/data/app_services.dart';
import 'package:vigilancia_durazno/data/local/pending_store.dart';

/// DOBLE DE PRUEBA del backend `sigat-durazno-api` (solo en `test/`, nunca en la app).
///
/// Responde con las MISMAS formas que el contrato real (`contracts/openapi.json`) en las
/// rutas que el backend ya implementa (login, sesión, inicio, perfil, avisos) y con
/// **501 NO_IMPLEMENTADO** en las demás, igual que el servidor hoy. Así las pruebas recorren
/// el cliente HTTP, los repositorios y las pantallas reales sin red.
///
/// No hay credenciales fijas: cada prueba crea sus cuentas con [crearCuenta], que devuelve
/// una contraseña aleatoria.
class BackendDePrueba {
  BackendDePrueba() {
    client = MockClient(_responder);
  }

  late final MockClient client;

  /// Peticiones recibidas: «MÉTODO /ruta?consulta».
  final peticiones = <String>[];

  /// Cuerpos JSON recibidos, por la misma clave.
  final cuerpos = <String, Object?>{};

  /// true = toda petición falla como si no hubiera red.
  bool sinRed = false;

  /// Respuestas para rutas que el backend real aún no implementa (lotes, trampas…), SOLO
  /// para probar la lógica del cliente cuando esas rutas existan. Clave = «GET /ruta».
  final respuestasExtra = <String, Object?>{};

  final operacionesRecibidas = <Map<String, dynamic>>[];

  final porRevisar = <String, String>{};

  final rechazadas = <String, String>{};

  final registrosAplicados = <String>[];

  final _visitasAceptadas = <String>{};

  final _porCliente = <String, String>{};

  final _bandeja = <Map<String, dynamic>>[];

  var _sigOper = 1000;

  final _cuentas = <String, _Cuenta>{};
  final _avisos = <Map<String, dynamic>>[];
  var _sigToken = 0;
  final _tokens = <String, _Cuenta>{};

  static String claveAleatoria() {
    const letras = 'abcdefghjkmnpqrstuvwxyzACDEFGHJKLMNPQRSTUVWXYZ2345679';
    final r = Random.secure();
    return List.generate(16, (_) => letras[r.nextInt(letras.length)]).join();
  }

  /// Registra una cuenta (como haría el administrador desde la web) y devuelve su contraseña.
  String crearCuenta(
      {required String usuario,
      required String nombre,
      required String rol,
      int? id}) {
    final clave = claveAleatoria();
    _cuentas[usuario.toLowerCase()] =
        _Cuenta(id ?? _cuentas.length + 1, usuario, nombre, rol, clave);
    return clave;
  }

  /// Agrega un aviso para el usuario (el backend los genera ante un evento real).
  void agregarAviso({
    required int usuaId,
    required String titulo,
    String cuerpo = '',
    String categoria = 'asignacion',
    Map<String, dynamic>? destino,
  }) =>
      _avisos.add({
        'usua_id': usuaId,
        'noti_id': _avisos.length + 1,
        'categoria': categoria,
        'titulo': titulo,
        'cuerpo': cuerpo,
        'creada_en': DateTime.now().toUtc().toIso8601String(),
        'leida_en': null,
        'leida': false,
        'destino': destino,
      });

  /// Conecta la app a este backend, con almacenamiento seguro y cola local en memoria.
  PendingStore conectarApp() {
    final pendientes = InMemoryPendingStore();
    AppServices.connect(
      client: ApiClient(
          client: client,
          store: MemorySecureStore(),
          baseUrl: 'http://backend.prueba/api/v1'),
      store: pendientes,
    );
    return pendientes;
  }

  Future<http.Response> _responder(http.Request req) async {
    if (sinRed) throw http.ClientException('Sin red (prueba)');
    final ruta = req.url.path.replaceFirst('/api/v1', '');
    final clave =
        '${req.method} $ruta${req.url.hasQuery ? '?${req.url.query}' : ''}';
    peticiones.add(clave);
    if (req.body.isNotEmpty) cuerpos[clave] = jsonDecode(req.body);

    if (req.method == 'POST' && ruta == '/auth/login') return _login(req);
    if (req.method == 'POST' && ruta == '/auth/recuperacion') {
      return _json(202, null);
    }

    final cuenta =
        _tokens[req.headers['Authorization']?.replaceFirst('Bearer ', '')];
    if (cuenta == null) {
      return _problema(
          401, 'TOKEN_INVALIDO', 'Su sesión terminó. Inicie sesión de nuevo.');
    }

    final extra = respuestasExtra['${req.method} $ruta'];
    if (extra != null) return _json(200, extra);

    switch ((req.method, ruta)) {
      case ('GET', '/auth/sesion'):
        return _json(200, cuenta.usuarioSesion);
      case ('POST', '/auth/logout'):
        _tokens.removeWhere((_, c) => c == cuenta);
        return _json(204, null);
      case ('GET', '/yo/inicio'):
        return _json(200, {
          'rol': cuenta.rol,
          'fecha': DateTime.now().toIso8601String().substring(0, 10),
          'datos_al': DateTime.now().toUtc().toIso8601String(),
          'notificaciones_no_leidas':
              _de(cuenta).where((a) => a['leida'] == false).length,
          'tecnico': null,
          'productor': null,
          'agronomo': null,
        });
      case ('GET', '/yo/perfil'):
        return _json(200, {
          'usua_id': cuenta.id,
          'nombre': cuenta.nombre,
          'usuario': cuenta.usuario,
          'correo': null,
          'telefono': null,
          'rol': cuenta.rol,
          'rol_descripcion': cuenta.rol,
          'foto_arch_id': null,
          'foto_url': null,
          'actualizado_en': null,
        });
      case ('GET', '/yo/notificaciones'):
        return _json(
            200, {'items': _de(cuenta).reversed.toList(), 'siguiente': null});
      case ('GET', '/yo/notificaciones/conteo'):
        return _json(200, {
          'no_leidas': _de(cuenta).where((a) => a['leida'] == false).length
        });
      case ('POST', '/yo/notificaciones/leidas'):
        for (final a in _de(cuenta)) {
          a['leida'] = true;
        }
        return _json(204, null);

      case ('POST', '/sincronizacion/lotes'):
        return _lotes(req);
      case ('GET', '/sincronizacion/operaciones'):
        return _json(200, _bandeja);
    }

    final leida = RegExp(r'^/yo/notificaciones/(\d+)/leida$').firstMatch(ruta);
    if (req.method == 'POST' && leida != null) {
      final a =
          _de(cuenta).where((x) => '${x['noti_id']}' == leida[1]).firstOrNull;
      if (a == null) {
        return _problema(404, 'AVISO_NO_ENCONTRADO', 'El aviso no existe.');
      }
      a['leida'] = true;
      return _json(204, null);
    }
    // Todo lo demás existe en el contrato pero el backend aún no lo implementa.
    return _problema(
        501, 'NO_IMPLEMENTADO', 'Funcionalidad pendiente de implementar.');
  }

  List<Map<String, dynamic>> _de(_Cuenta c) =>
      _avisos.where((a) => a['usua_id'] == c.id).toList();

  http.Response _lotes(http.Request req) {
    final b = jsonDecode(req.body) as Map<String, dynamic>;
    final dispId = b['disp_id']?.toString() ?? '';
    final operaciones = (b['operaciones'] as List?) ?? const [];
    if (dispId.isEmpty) {
      return _problema(422, 'DISP_ID_REQUERIDO', 'Falta disp_id.');
    }
    if (operaciones.isEmpty || operaciones.length > 200) {
      return _problema(422, 'LOTE_INVALIDO',
          'El lote debe tener entre 1 y 200 operaciones.');
    }

    final resultados = <Map<String, dynamic>>[];
    for (final raw in operaciones) {
      final op = Map<String, dynamic>.from(raw as Map);
      operacionesRecibidas.add(op);
      final registroId = op['registro_id']?.toString() ?? '';
      final clienteId = op['cliente_id']?.toString() ?? '';
      final entidad = op['entidad']?.toString() ?? '';
      final hash = op['hash_contenido']?.toString() ?? '';

      final contenido = <String, dynamic>{
        'entidad': entidad,
        'accion': op['accion'],
        'registro_id': registroId,
        'version': op['version'],
        'linaje': op['linaje'],
        't_observacion': CanonicalJson.instanteCanonico(
            DateTime.parse(op['t_observacion'].toString())),
        'datos': op['datos'],
      };
      if (CanonicalJson.sha256Hex(contenido) != hash) {
        resultados.add(_resultado(op, null, 'rechazada',
            codigo: 'HUELLA_INVALIDA',
            motivo: 'La huella del contenido no coincide con lo enviado.'));
        continue;
      }

      final clave = '$dispId|$clienteId';
      final previo = _porCliente[clave];
      if (previo != null) {
        resultados.add(_resultado(
            op, null, previo == hash ? 'idempotente_repetida' : 'rechazada',
            codigo: previo == hash ? null : 'CONFLICTO_CONTENIDO',
            motivo: previo == hash
                ? null
                : 'Mismo cliente_id con otro contenido.'));
        continue;
      }

      if (entidad == 'lectura_trampa') {
        final datos = Map<String, dynamic>.from(op['datos'] as Map);
        final visiId = datos['visi_id']?.toString();
        if (visiId == null || !_visitasAceptadas.contains(visiId)) {
          _porCliente[clave] = hash;
          resultados.add(_resultado(op, null, 'rechazada',
              codigo: 'REFERENCIA_PENDIENTE',
              motivo: 'La lectura no tiene una visita aceptada.'));
          continue;
        }
      }

      if (rechazadas.containsKey(registroId)) {
        _porCliente[clave] = hash;
        final operId = _sigOper++;
        _bandeja.add(
            _filaBandeja(operId, op, 'rechazada', rechazadas[registroId]!));
        resultados.add(_resultado(op, operId, 'rechazada',
            motivo: rechazadas[registroId]));
        continue;
      }
      if (porRevisar.containsKey(registroId)) {
        _porCliente[clave] = hash;
        final operId = _sigOper++;
        _bandeja
            .add(_filaBandeja(operId, op, 'revisar', porRevisar[registroId]!));
        resultados.add(
            _resultado(op, operId, 'revisar', motivo: porRevisar[registroId]));
        continue;
      }

      _porCliente[clave] = hash;
      final operId = _sigOper++;
      if (entidad == 'visita') _visitasAceptadas.add(registroId);
      registrosAplicados.add(registroId);
      resultados.add(_resultado(op, operId, 'alta_nueva'));
    }

    final ahora = DateTime.now().toUtc().toIso8601String();
    return _json(200, {
      'resultados': resultados,
      'cursor': '$ahora|$_sigOper',
      'servidor_utc': ahora,
    });
  }

  Map<String, dynamic> _resultado(
    Map<String, dynamic> op,
    int? operId,
    String resultado, {
    String? codigo,
    String? motivo,
  }) =>
      {
        'cliente_id': op['cliente_id'],
        'oper_id': operId,
        'resultado': resultado,
        'motivo': motivo,
        'codigo': codigo,
        'registro_id': op['registro_id'],
        'version': op['version'],
        'reproceso': 'no_aplica',
        'fecha_efecto': null,
        'reintentable': false,
      };

  Map<String, dynamic> _filaBandeja(int operId, Map<String, dynamic> op,
          String clasificacion, String motivo) =>
      {
        'oper_id': operId,
        'cliente_id': op['cliente_id'],
        'entidad': op['entidad'],
        'accion': op['accion'],
        'registro_id': op['registro_id'],
        'version': op['version'],
        'clasificacion': clasificacion,
        'motivo': motivo,
        't_captura': op['t_captura'],
        't_recepcion': DateTime.now().toUtc().toIso8601String(),
        'datos': op['datos'],
      };

  http.Response _login(http.Request req) {
    final b = jsonDecode(req.body) as Map<String, dynamic>;
    final c = _cuentas[(b['usuario'] as String).trim().toLowerCase()];
    if (c == null || c.clave != b['contrasena']) {
      return _problema(
          401, 'CREDENCIALES_INVALIDAS', 'Usuario o contraseña incorrectos.');
    }
    final token = 'acceso-${_sigToken++}';
    _tokens[token] = c;
    return _json(200, {
      'token': token,
      'expira_en': 900,
      'token_refresco': 'refresco-$token',
      'disp_id': '00000000-0000-4000-8000-000000000001',
      'user': c.usuarioSesion,
    });
  }

  static http.Response _json(int status, Object? cuerpo) => http.Response.bytes(
        cuerpo == null ? const <int>[] : utf8.encode(jsonEncode(cuerpo)),
        status,
        headers: {'content-type': 'application/json'},
      );

  static http.Response _problema(int status, String codigo, String detalle) =>
      http.Response.bytes(
        utf8.encode(jsonEncode({
          'status': status,
          'title': 'Error',
          'detail': detalle,
          'codigo': codigo
        })),
        status,
        headers: {'content-type': 'application/problem+json'},
      );
}

class _Cuenta {
  _Cuenta(this.id, this.usuario, this.nombre, this.rol, this.clave);
  final int id;
  final String usuario;
  final String nombre;
  final String rol;
  final String clave;

  Map<String, dynamic> get usuarioSesion => {
        'id': id,
        'nombre': nombre,
        'iniciales': nombre.split(' ').map((p) => p[0]).take(2).join(),
        'usuario': usuario,
        'correo': null,
        'rol': rol,
        'rol_descripcion': rol,
        'predio_etiqueta': null,
        'requiere_cambio_contrasena': false,
      };
}

/// Almacenamiento seguro en memoria (en las pruebas no existe el Keystore/Keychain).
class MemorySecureStore extends SecureStore {
  final _m = <String, String>{};

  @override
  Future<String?> get accessToken async => _m['acceso'];
  @override
  Future<String?> get refreshToken async => _m['refresco'];
  @override
  Future<String?> get deviceId async => _m['disp'];
  @override
  Future<String?> get rememberedUser async => _m['recordado'];
  @override
  Future<String?> get sessionUser async => _m['sesion'];

  @override
  Future<void> saveTokens({required String access, String? refresh}) async {
    _m['acceso'] = access;
    if (refresh != null) _m['refresco'] = refresh;
  }

  @override
  Future<void> saveDeviceId(String id) async => _m['disp'] = id;

  @override
  Future<void> saveRememberedUser(String? usuario) async {
    if (usuario == null) {
      _m.remove('recordado');
    } else {
      _m['recordado'] = usuario;
    }
  }

  @override
  Future<void> saveSessionUser(String json) async => _m['sesion'] = json;

  @override
  Future<void> clearTokens() async {
    _m.remove('acceso');
    _m.remove('refresco');
    _m.remove('sesion');
  }
}
