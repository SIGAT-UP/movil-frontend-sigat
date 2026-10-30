import '../models/user_session.dart';

/// Error controlado que la UI muestra en la caja roja.
class AuthException implements Exception {
  const AuthException(this.title, [this.message]);
  final String title;
  final String? message;
  @override
  String toString() => '$title ${message ?? ''}';
}

/// Contrato de autenticación. La UI SOLO conoce esta interfaz.
/// Implementación real: `ApiAuthRepository` (backend `sigat-durazno-api`).
abstract class AuthRepository {
  Future<UserSession> login({required String username, required String password, required bool remember});

  Future<void> requestPasswordReset(String email);

  /// Usuario recordado para precargar el campo (o null).
  Future<String?> getRememberedUser();

  Future<void> logout();

  /// Al abrir la app: la sesión guardada en el teléfono, si sigue siendo válida
  /// (o la última conocida si no hay conexión, para trabajar en campo). null = pedir login.
  Future<UserSession?> restoreSession();
}
