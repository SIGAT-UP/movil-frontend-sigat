import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';
import '../../data/app_services.dart';
import '../../data/repositories/auth_repository.dart';

/// A02 — Recuperación de acceso.
class RecoverPasswordScreen extends StatefulWidget {
  const RecoverPasswordScreen({super.key});

  @override
  State<RecoverPasswordScreen> createState() => _RecoverPasswordScreenState();
}

class _RecoverPasswordScreenState extends State<RecoverPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AppServices.auth.requestPasswordReset(_emailCtrl.text.trim());
      if (mounted) setState(() => _sent = true);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message ?? e.title);
    } catch (_) {
      if (mounted) setState(() => _error = 'No pudimos enviar las instrucciones. Intente de nuevo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SimpleAppBar(title: 'Recuperar acceso'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenH),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SoftIconCircle(icon: Icons.mail_outline),
                const SizedBox(height: AppSpacing.lg),
                const Text('¿Olvidaste tu contraseña?',
                    style: AppText.h1),
                const SizedBox(height: 6),
                const Text(
                  'Ingresa tu correo electrónico y te enviaremos las instrucciones para crear una nueva contraseña.',
                  style: AppText.secondary,
                ),
                const SizedBox(height: AppSpacing.xl),
                if (_sent) ...[
                  AlertBanner(
                    type: AlertType.success,
                    title: 'Revisa tu correo',
                    message: 'Si ${_emailCtrl.text.trim()} está registrado, recibirás las instrucciones en unos minutos.',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (_error != null) ...[
                  AlertBanner(title: 'No se pudo enviar', message: _error),
                  const SizedBox(height: AppSpacing.lg),
                ],
                AppTextField(
                  label: 'Correo electrónico',
                  controller: _emailCtrl,
                  hint: 'nombre@correo.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.send,
                  enabled: !_loading,
                  onSubmitted: (_) => _send(),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Ingrese su correo';
                    if (!_emailRegex.hasMatch(v.trim())) return 'Correo no válido';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  label: _sent ? 'Reenviar instrucciones' : 'Enviar instrucciones',
                  loadingLabel: 'Enviando...',
                  isLoading: _loading,
                  color: AppColors.primaryDark,
                  onPressed: _send,
                ),
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: AppLinkButton(
                    label: 'Volver a iniciar sesión',
                    fontSize: 13,
                    onPressed: () => Navigator.of(context).pop(),
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
