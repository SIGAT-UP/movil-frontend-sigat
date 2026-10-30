import 'package:flutter/foundation.dart';

import '../../data/app_services.dart';
import '../../data/models/user_session.dart';
import '../../data/repositories/auth_repository.dart';

/// Estados del diseño: A01 (idle), A02 (loading), A03 (error).
enum LoginStatus { idle, loading, error }

class LoginController extends ChangeNotifier {
  LoginController({AuthRepository? repository}) : _repo = repository ?? AppServices.auth;

  final AuthRepository _repo;

  LoginStatus status = LoginStatus.idle;
  bool rememberUser = true;
  String? errorTitle;
  String? errorMessage;
  String? rememberedUser;

  bool get isLoading => status == LoginStatus.loading;
  bool get hasError => status == LoginStatus.error;

  Future<void> init() async {
    rememberedUser = await _repo.getRememberedUser();
    notifyListeners();
  }

  void toggleRemember(bool v) {
    rememberUser = v;
    notifyListeners();
  }

  /// Al escribir de nuevo se limpia el error (vuelve a A01).
  void clearError() {
    if (!hasError) return;
    status = LoginStatus.idle;
    notifyListeners();
  }

  Future<UserSession?> login(String username, String password) =>
      _run(() => _repo.login(username: username, password: password, remember: rememberUser));

  Future<UserSession?> _run(Future<UserSession> Function() action) async {
    status = LoginStatus.loading;
    notifyListeners();
    try {
      final session = await action();
      AppServices.session.value = session;
      status = LoginStatus.idle;
      notifyListeners();
      return session;
    } on AuthException catch (e) {
      _setError(e.title, e.message);
    } catch (_) {
      _setError('No pudimos iniciar sesión', 'Ocurrió un error inesperado. Intente de nuevo.');
    }
    return null;
  }

  void _setError(String title, String? message) {
    status = LoginStatus.error;
    errorTitle = title;
    errorMessage = message;
    notifyListeners();
  }
}
