import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/widgets/widgets.dart';
import '../../data/app_services.dart';
import 'login_controller.dart';

/// A01 Login común · A02 Cargando · A03 Error (una sola pantalla con estados).
///
/// Presentación: cabecera con degradado en el tercio superior y una tarjeta
/// blanca con el formulario. Al aparecer, la cabecera baja, la tarjeta sube y
/// sus elementos entran uno tras otro (un solo AnimationController; tiempos en
/// [AppMotion]). La lógica de acceso es la de siempre: [LoginController].
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // ---------------- Entrada animada ----------------

  /// Elementos de la tarjeta que entran escalonados (título, usuario,
  /// contraseña, recordar/olvidó, botón, pie de conexión).
  static const _items = 6;
  static final _total = AppMotion.loginTotal(_items);

  late final AnimationController _entrance = AnimationController(vsync: this, duration: _total);

  late final Animation<Offset> _headerSlide = _entrance.drive(
    Tween(begin: const Offset(0, -1), end: Offset.zero).chain(CurveTween(
      curve: AppMotion.phase(Duration.zero, AppMotion.loginHeader, _total, curve: AppMotion.enter),
    )),
  );

  late final Animation<Offset> _cardSlide = _entrance.drive(
    Tween(begin: const Offset(0, 1), end: Offset.zero).chain(CurveTween(
      curve: AppMotion.phase(AppMotion.loginCardStart, AppMotion.loginCard, _total, curve: AppMotion.enter),
    )),
  );

  late final List<Animation<double>> _itemFade = [
    for (var i = 0; i < _items; i++) _entrance.drive(CurveTween(curve: _itemPhase(i))),
  ];

  late final List<Animation<Offset>> _itemRise = [
    for (var i = 0; i < _items; i++)
      _entrance.drive(
        Tween(begin: const Offset(0, AppMotion.loginItemRise), end: Offset.zero)
            .chain(CurveTween(curve: _itemPhase(i))),
      ),
  ];

  static Interval _itemPhase(int i) => AppMotion.phase(
        AppMotion.loginItemsStart + AppMotion.loginItemStep * i,
        AppMotion.loginItem,
        _total,
        curve: AppMotion.enter,
      );

  /// Envuelve el elemento `i` de la tarjeta con su fundido y su subida.
  Widget _stagger(int i, Widget child) => FadeTransition(
        opacity: _itemFade[i],
        child: SlideTransition(position: _itemRise[i], child: child),
      );

  bool _entranceChecked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entranceChecked) return;
    _entranceChecked = true;
    final reducir = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reducir) {
      _entrance.value = 1; // sin movimiento: todo en su sitio desde el inicio
    } else {
      _entrance.forward();
    }
  }

  // ---------------- Formulario ----------------

  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _controller = LoginController();

  @override
  void initState() {
    super.initState();
    _controller.init().then((_) {
      if (_controller.rememberedUser != null && _userCtrl.text.isEmpty) {
        _userCtrl.text = _controller.rememberedUser!;
      }
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final session = await _controller.login(_userCtrl.text, _passCtrl.text);
    if (session != null && mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.accessContext);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tercio superior de la pantalla completa (no del área visible): así la
    // cabecera no salta cuando se abre el teclado.
    final alturaCabecera = (MediaQuery.sizeOf(context).height / 3).clamp(220.0, 340.0);
    const radioTarjeta = 28.0;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // --- Cabecera con degradado: baja desde arriba ---
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            // Se extiende bajo las esquinas redondeadas de la tarjeta.
            height: alturaCabecera + radioTarjeta * 2,
            child: SlideTransition(
              position: _headerSlide,
              child: const _LoginHeader(bottomInset: radioTarjeta * 2),
            ),
          ),

          // --- Tarjeta blanca: sube desde abajo ---
          // Dos tramos que se leen como una sola tarjeta:
          //   1. el formulario, con su alto natural;
          //   2. el resto, que rellena hasta el borde inferior con el pie abajo.
          // Si no cabe (pantalla baja, teclado abierto, letra grande), se desplaza.
          SlideTransition(
            position: _cardSlide,
            child: ListenableBuilder(
              listenable: Listenable.merge([_controller, AppServices.isOnline]),
              builder: (context, _) {
                final c = _controller;
                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: SizedBox(height: alturaCabecera)),

                    // 1 · Formulario
                    SliverToBoxAdapter(
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(radioTarjeta)),
                          boxShadow: AppShadows.nav,
                        ),
                        child: ResponsiveBody(
                          maxWidth: 460,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                                AppSpacing.xl, AppSpacing.xl + 4, AppSpacing.xl, 0),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // 0 · Bienvenida
                                  _stagger(
                                    0,
                                    const Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Te damos la bienvenida', style: AppText.h1),
                                        SizedBox(height: AppSpacing.xs),
                                        Text('Ingresa con tu usuario y contraseña.', style: AppText.secondary),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xl),

                                  // 1 · Usuario (con el error encima, si lo hay)
                                  _stagger(
                                    1,
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        if (c.hasError) ...[
                                          AlertBanner(title: c.errorTitle ?? '', message: c.errorMessage),
                                          const SizedBox(height: AppSpacing.lg),
                                        ],
                                        AppTextField(
                                          label: 'Usuario o correo',
                                          controller: _userCtrl,
                                          hint: 'usuario o nombre@correo.com',
                                          icon: Icons.person_outline,
                                          hasError: c.hasError,
                                          enabled: !c.isLoading,
                                          keyboardType: TextInputType.emailAddress,
                                          textInputAction: TextInputAction.next,
                                          onChanged: (_) => c.clearError(),
                                          validator: (v) =>
                                              (v == null || v.trim().isEmpty) ? 'Ingrese su usuario' : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),

                                  // 2 · Contraseña
                                  _stagger(
                                    2,
                                    AppTextField(
                                      label: 'Contraseña',
                                      controller: _passCtrl,
                                      hint: 'Contraseña',
                                      icon: Icons.lock_outline,
                                      isPassword: true,
                                      hasError: c.hasError,
                                      enabled: !c.isLoading,
                                      textInputAction: TextInputAction.done,
                                      onChanged: (_) => c.clearError(),
                                      onSubmitted: (_) => _submit(),
                                      validator: (v) => (v == null || v.isEmpty) ? 'Ingrese su contraseña' : null,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),

                                  // 3 · Recordar usuario / ¿Olvidó su contraseña?
                                  // Wrap: si no caben en una línea, el enlace baja a la siguiente.
                                  _stagger(
                                    3,
                                    Wrap(
                                      alignment: WrapAlignment.spaceBetween,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      runSpacing: AppSpacing.xs,
                                      children: [
                                        AppCheckboxRow(
                                          label: 'Recordar usuario',
                                          value: c.rememberUser,
                                          onChanged: c.isLoading ? null : c.toggleRemember,
                                        ),
                                        AppLinkButton(
                                          label: '¿Olvidó su contraseña?',
                                          onPressed: c.isLoading
                                              ? null
                                              : () => Navigator.of(context).pushNamed(AppRoutes.recover),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.lg),

                                  // 4 · Botón principal
                                  _stagger(
                                    4,
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        PrimaryButton(
                                          label: 'Iniciar sesión',
                                          loadingLabel: 'Ingresando...',
                                          isLoading: c.isLoading,
                                          color: AppColors.primaryDark,
                                          onPressed: _submit,
                                        ),
                                        if (c.isLoading) ...[
                                          const SizedBox(height: AppSpacing.sm),
                                          const Center(child: AppInlineLoader(label: 'Validando credenciales...')),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 2 · Resto de la tarjeta, con el pie al fondo
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: ColoredBox(
                        color: AppColors.background,
                        child: SafeArea(
                          top: false,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.md),
                              // 5 · Pie: conexión real (el inicio de sesión ya va contra el backend)
                              child: _stagger(
                                5,
                                ConnectionFooter(isOnline: AppServices.isOnline.value),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Cabecera del login: foto (o ilustración) del huerto de durazno de fondo,
/// con el logo PNG encima, tal cual, sin placa.
///
/// La imagen es `assets/images/login_hero.jpg`: para usar otra foto del
/// cultivo basta con reemplazar ese archivo. Un velo verde profundo abajo
/// asegura que el nombre de la app se lea en blanco sobre cualquier foto.
class _LoginHeader extends StatelessWidget {
  const _LoginHeader({required this.bottomInset});

  static const imagePath = 'assets/images/login_hero.jpg';

  /// Parte inferior que queda tapada por la tarjeta.
  final double bottomInset;

  static const _sombraTexto = [Shadow(color: Color(0x99000000), blurRadius: 8, offset: Offset(0, 1))];

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const AssetOrFallback(imagePath, fallbackIcon: Icons.agriculture),

        // Velo: transparente arriba (se ve el cielo), verde profundo abajo
        // (donde va el texto blanco).
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              // A la altura del texto el velo ronda 0,6: blanco y el subtítulo
              // pasan AA incluso sobre las copas más claras de la imagen.
              stops: const [0, .3, 1],
              colors: [
                AppColors.navInk.withValues(alpha: 0),
                AppColors.navInk.withValues(alpha: .35),
                AppColors.navInk.withValues(alpha: .9),
              ],
            ),
          ),
        ),

        SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo PNG sobre un halo de luz suave: se separa del fondo
                  // sin encerrarlo en una placa.
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withValues(alpha: .8),
                              Colors.white.withValues(alpha: .35),
                              Colors.white.withValues(alpha: 0),
                            ],
                            stops: const [0, .55, 1],
                          ),
                        ),
                      ),
                      const BrandLogo(size: 104),
                    ],
                  ),
                  Text(
                    'Vigilancia Durazno',
                    style: AppText.h2.copyWith(color: AppColors.navOnInk, shadows: _sombraTexto),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Monitoreo fitosanitario',
                    style: AppText.bodySm.copyWith(color: AppColors.navOnInkSoft, shadows: _sombraTexto),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
