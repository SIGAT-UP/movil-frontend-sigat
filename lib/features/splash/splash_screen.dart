import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/widgets/widgets.dart';
import '../../data/app_services.dart';
import '../../data/models/user_session.dart';
import '../auth/login_screen.dart';

/// Pantalla de bienvenida animada. Solo se ve al abrir la app.
///
/// Un único AnimationController recorre toda la secuencia; cada fase toma su
/// tramo con un `Interval` (ver [AppMotion]):
///   1. el logo entra desde el borde izquierdo hasta el centro (easeOutBack);
///   2. la frase aparece debajo con fundido y una leve subida;
///   3. pausa para leer;
///   4. logo y frase se desvanecen.
/// Al terminar, pasa al login con un PageRouteBuilder (fundido), o directo al
/// inicio del rol si ya hay una sesión abierta.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  /// Eslogan bajo el logo.
  /// Alternativas: "Del huerto al registro, aun sin señal" ·
  ///               "Monitoreo fitosanitario del durazno de exportación"
  static const tagline = 'Vigilancia del durazno, trampa por trampa';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: AppMotion.splashTotal);

  // Fases, todas derivadas del mismo controlador.
  late final Animation<Offset> _logoSlide = _c.drive(
    Tween(begin: const Offset(-1, 0), end: Offset.zero).chain(CurveTween(
      curve: AppMotion.phase(Duration.zero, AppMotion.splashLogoIn, AppMotion.splashTotal,
          curve: AppMotion.logoIn),
    )),
  );

  late final Animation<double> _taglineFade = _c.drive(CurveTween(
    curve: AppMotion.phase(AppMotion.splashTaglineStart, AppMotion.splashTaglineIn, AppMotion.splashTotal,
        curve: AppMotion.enter),
  ));

  late final Animation<Offset> _taglineRise = _c.drive(
    Tween(begin: const Offset(0, AppMotion.taglineRise), end: Offset.zero).chain(CurveTween(
      curve: AppMotion.phase(AppMotion.splashTaglineStart, AppMotion.splashTaglineIn, AppMotion.splashTotal,
          curve: AppMotion.enter),
    )),
  );

  late final Animation<double> _exitFade = _c.drive(
    Tween(begin: 1.0, end: 0.0).chain(CurveTween(
      curve: AppMotion.phase(AppMotion.splashExitStart, AppMotion.splashExit, AppMotion.splashTotal,
          curve: AppMotion.exit),
    )),
  );

  bool _started = false;
  bool _left = false;

  /// Se intenta restaurar la sesión guardada MIENTRAS corre la animación.
  late final Future<UserSession?> _restaurada = AppServices.session.value != null
      ? Future.value(AppServices.session.value)
      : AppServices.auth.restoreSession().catchError((Object _) => null);

  @override
  void initState() {
    super.initState();
    _restaurada; // arranca ya
    _c.addStatusListener((status) {
      if (status == AnimationStatus.completed) _next();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // Con "reducir movimiento" no hay desplazamientos: se arranca en la pausa,
    // con el logo y la frase ya en su sitio, y solo se ve el fundido de salida.
    final reducir = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reducir) {
      _c.value = AppMotion.splashHoldStart.inMicroseconds / AppMotion.splashTotal.inMicroseconds;
    }
    _c.forward();
  }

  /// Sesión abierta → inicio de su rol. Si no → login con transición propia.
  Future<void> _next() async {
    if (_left || !mounted) return;
    _left = true;

    final sesion = AppServices.session.value ?? await _restaurada;
    if (!mounted) return;
    if (sesion != null) AppServices.session.value = sesion;
    final inicio = sesion == null ? null : AppRoutes.homeFor(sesion.role);
    if (inicio != null) {
      Navigator.of(context).pushReplacementNamed(inicio);
      return;
    }
    Navigator.of(context).pushReplacement(_loginRoute());
  }

  /// Fundido hacia el login. La cabecera y la tarjeta tienen su propia entrada
  /// escalonada dentro de LoginScreen, que arranca al mismo tiempo.
  static Route<void> _loginRoute() => PageRouteBuilder<void>(
        settings: const RouteSettings(name: AppRoutes.login),
        transitionDuration: AppMotion.toLogin,
        reverseTransitionDuration: AppMotion.toLogin,
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation.drive(CurveTween(curve: AppMotion.enter)),
          child: child,
        ),
      );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _exitFade,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // El hijo ocupa todo el ancho: Offset(-1, 0) lo deja justo fuera
                // del borde izquierdo, y desde ahí entra hasta el centro.
                SlideTransition(
                  position: _logoSlide,
                  child: const SizedBox(
                    width: double.infinity,
                    child: Center(child: BrandLogo(size: 190)),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                FadeTransition(
                  opacity: _taglineFade,
                  child: SlideTransition(
                    position: _taglineRise,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      child: Text(
                        SplashScreen.tagline,
                        textAlign: TextAlign.center,
                        style: AppText.secondary.copyWith(fontSize: 14, letterSpacing: 0.2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
