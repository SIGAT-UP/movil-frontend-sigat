import '../app_services.dart';
import '../repositories/field_repositories.dart';

/// No hay una sesión válida a la que asociar un registro local.
class SinSesionException extends DataException {
  const SinSesionException([
    super.message = 'No hay una sesión válida. Inicie sesión de nuevo; lo guardado en este teléfono se conserva.',
  ]);
}

/// Dueño de los registros de la cola local ([PendingStore]).
///
/// Cada registro guardado en el teléfono pertenece al usuario que lo capturó: así dos cuentas
/// que usan el mismo teléfono nunca ven ni envían lo del otro. Esta clase es el ÚNICO lugar
/// donde se decide quién es el dueño:
///
/// * Para **guardar, modificar o borrar** se usa [requerido] (o [exigirMismoUsuario]): sin una
///   sesión válida lanza [SinSesionException] ANTES de tocar la cola.
/// * Para **leer** se usa [paraLectura]: sin sesión válida devuelve [ninguno], que no coincide
///   con ningún registro (tampoco con registros antiguos guardados con dueño vacío).
class RecordOwner {
  RecordOwner._();

  /// Identificador que nunca es el de un usuario real (los `usua_id` del backend son números).
  static const ninguno = '-';

  static final _formato = RegExp(r'^[0-9]{1,18}$');

  /// `usua_id` del backend: solo dígitos, no vacío.
  static bool esValido(String? userId) => userId != null && _formato.hasMatch(userId);

  /// Usuario de la sesión actual. Lanza [SinSesionException] si no hay sesión o el id no es válido.
  static String requerido() {
    final id = AppServices.session.value?.userId;
    if (!esValido(id)) throw const SinSesionException();
    return id!;
  }

  /// Igual que [requerido], y además exige que [userId] sea el usuario de la sesión.
  static String exigirMismoUsuario(String userId) {
    final yo = requerido();
    if (userId != yo) {
      throw const SinSesionException('El registro no corresponde al usuario de la sesión actual.');
    }
    return yo;
  }

  /// Dueño para CONSULTAR la cola: SIEMPRE el usuario de la sesión, o [ninguno].
  ///
  /// Si se pasa [userId] (las pantallas lo envían por compatibilidad con los contratos de los
  /// repositorios), debe ser el de la sesión: un identificador distinto, vacío o inválido
  /// devuelve [ninguno], que no coincide con ningún registro. Así ninguna llamada puede leer los
  /// pendientes de otra cuenta guardados en el mismo teléfono, aunque reciba su `usua_id`.
  static String paraLectura([String? userId]) {
    final sesion = AppServices.session.value?.userId;
    if (!esValido(sesion)) return ninguno;
    if (userId != null && userId != sesion) return ninguno;
    return sesion!;
  }
}
