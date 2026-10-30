import 'package:flutter/material.dart';

import '../../app/shell_nav.dart';
import '../../core/widgets/widgets.dart';
import '../../data/app_services.dart';
import '../../data/models/producer.dart';
import 'producer_controller.dart';

/// P03-P — Registrar aplicación (+ confirmación "Aplicación registrada correctamente.").
class RegisterApplicationScreen extends StatefulWidget {
  const RegisterApplicationScreen({super.key});

  @override
  State<RegisterApplicationScreen> createState() => _RegisterApplicationScreenState();
}

class _RegisterApplicationScreenState extends State<RegisterApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productCtrl = TextEditingController();
  final _doseCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  late final _responsibleCtrl =
      TextEditingController(text: AppServices.session.value?.displayName ?? '');

  DateTime _date = DateTime.now();
  bool _saving = false;
  bool _saved = false;

  @override
  void dispose() {
    _productCtrl.dispose();
    _doseCtrl.dispose();
    _areaCtrl.dispose();
    _responsibleCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ProducerController.instance.saveApplication(PhytoApplication(
        id: 'app-${DateTime.now().microsecondsSinceEpoch}',
        date: _date,
        product: _productCtrl.text.trim(),
        doseMlPerLiter: AppNumberField.parse(_doseCtrl.text)!,
        areaHa: AppNumberField.parse(_areaCtrl.text)!,
        responsible: _responsibleCtrl.text.trim(),
      ));
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saved = true;
      });
      // Se muestra la confirmación un momento y vuelve al inicio.
      await Future<void>.delayed(const Duration(milliseconds: 1300));
      if (mounted) ProducerNav.goTo(context, ProducerTab.inicio);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppMessenger.error('No se pudo guardar el registro', message: 'Revisa los datos e intenta de nuevo.');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si hay datos sin guardar, el botón atrás pregunta antes de salir.
    return ListenableBuilder(
      listenable: Listenable.merge([_productCtrl, _doseCtrl, _areaCtrl]),
      builder: (context, _) => DiscardChangesGuard(
        hasChanges: !_saved &&
              (_productCtrl.text.trim().isNotEmpty ||
                  _doseCtrl.text.trim().isNotEmpty ||
                  _areaCtrl.text.trim().isNotEmpty),
        message: 'La aplicación no se registrará.',
        child: Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SimpleAppBar(title: 'Registrar aplicación'),
      body: Form(
        key: _formKey,
        child: ResponsiveBody(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenH),
            children: [
              AppDateField(
                label: 'Fecha de la aplicación',
                value: _date,
                lastDate: DateTime.now(),
                enabled: !_saved,
                onChanged: (d) => setState(() => _date = d ?? DateTime.now()),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Producto utilizado',
                controller: _productCtrl,
                hint: 'Nombre del producto',
                enabled: !_saved,
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Indica el producto utilizado' : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppNumberField(
                label: 'Dosis (mililitros por litro de agua)',
                controller: _doseCtrl,
                hint: 'Ej. 2',
                decimals: 2,
                min: 0,
                unit: 'ml/L',
                enabled: !_saved,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppNumberField(
                label: 'Área aplicada (hectáreas)',
                controller: _areaCtrl,
                hint: 'Ej. 1,2',
                decimals: 2,
                min: 0,
                unit: 'ha',
                enabled: !_saved,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Persona responsable',
                controller: _responsibleCtrl,
                enabled: !_saved,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Indica la persona responsable' : null,
              ),
              ValueListenableBuilder<bool>(
                valueListenable: AppServices.isOnline,
                builder: (_, online, __) => online
                    ? const SizedBox.shrink()
                    : const Padding(
                        padding: EdgeInsets.only(top: AppSpacing.lg),
                        child: AlertBanner(
                          type: AlertType.info,
                          title: 'Sin conexión — se guardará en el dispositivo.',
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomActions(children: [
        if (_saved) const SuccessToastBar('Aplicación registrada correctamente.'),
        PrimaryButton(
          label: 'Guardar',
          loadingLabel: 'Guardando...',
          isLoading: _saving,
          color: AppColors.primaryDark,
          onPressed: _saved ? null : _save,
        ),
      ]),
        ),
      ),
    );
  }
}
