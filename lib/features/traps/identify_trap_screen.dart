import 'package:flutter/material.dart';

import '../../app/shell_nav.dart';
import '../../core/widgets/widgets.dart';
import 'trap_flow.dart';

/// M12c-T — Identificar trampa (ingreso manual del código ICA).
class IdentifyTrapScreen extends StatefulWidget {
  const IdentifyTrapScreen({super.key, this.initialCode});
  final String? initialCode;

  @override
  State<IdentifyTrapScreen> createState() => _IdentifyTrapScreenState();
}

class _IdentifyTrapScreenState extends State<IdentifyTrapScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _codeCtrl = TextEditingController(text: widget.initialCode);
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _validate() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final lookup = await lookupTrap(_codeCtrl.text);
      if (!mounted) return;
      if (lookup == null) {
        setState(() => _error = 'El código no está en el catálogo descargado del predio. Revísalo e intenta de nuevo.');
      } else {
        openTrapIdentified(context, lookup, replace: true);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SimpleAppBar(title: 'Identificar trampa'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenH),
          children: [
            const AppCard(
              tone: AppCardTone.highlighted,
              child: Column(
                children: [
                  Text('Ingresa el código ICA', style: AppText.h2),
                  SizedBox(height: 4),
                  Text('Escribe el código que aparece impreso en la trampa Jackson',
                      textAlign: TextAlign.center, style: AppText.caption),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    label: 'Código de la trampa',
                    controller: _codeCtrl,
                    hint: 'Ej. 54518-602-5 o ICA-005',
                    hasError: _error != null,
                    enabled: !_loading,
                    textInputAction: TextInputAction.search,
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                    onSubmitted: (_) => _validate(),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el código' : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (_error != null) ...[
                    AlertBanner(title: 'Trampa no encontrada', message: _error),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  const AlertBanner(
                    type: AlertType.warning,
                    title: 'El código ICA identifica la trampa dentro del lote y permite registrar su lectura.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActions(children: [
        PrimaryButton(
          label: 'Validar código',
          loadingLabel: 'Validando...',
          icon: Icons.search,
          isLoading: _loading,
          color: AppColors.primaryDark,
          onPressed: _validate,
        ),
        SecondaryButton(label: 'Volver al mapa', onPressed: () => ShellNav.goTo(context, AppTab.mapa)),
      ]),
    );
  }
}
