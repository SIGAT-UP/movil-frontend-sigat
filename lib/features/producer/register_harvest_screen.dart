import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/widgets/widgets.dart';
import '../../data/app_services.dart';
import '../../data/models/producer.dart';
import 'producer_controller.dart';

/// P04-P — Registrar cosecha. Al guardar va a "Cosecha registrada".
class RegisterHarvestScreen extends StatefulWidget {
  const RegisterHarvestScreen({super.key});

  @override
  State<RegisterHarvestScreen> createState() => _RegisterHarvestScreenState();
}

class _RegisterHarvestScreenState extends State<RegisterHarvestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _volumeCtrl = TextEditingController();
  DateTime? _expected;
  DateTime? _actual;
  String? _expectedError;
  bool _saving = false;

  @override
  void dispose() {
    _volumeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final formOk = _formKey.currentState!.validate();
    setState(() => _expectedError = _expected == null ? 'Selecciona la fecha esperada' : null);
    if (!formOk || _expected == null) return;

    setState(() => _saving = true);
    final report = HarvestReport(
      id: 'har-${DateTime.now().microsecondsSinceEpoch}',
      expectedDate: _expected!,
      actualDate: _actual,
      volumeKg: AppNumberField.parse(_volumeCtrl.text)!,
    );
    try {
      await ProducerController.instance.saveHarvest(report);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.producerHarvestDone, arguments: report);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppMessenger.error('No se pudo guardar el registro', message: 'Revisa los datos e intenta de nuevo.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Si hay datos sin guardar, el botón atrás pregunta antes de salir.
    return ListenableBuilder(
      listenable: Listenable.merge([_volumeCtrl]),
      builder: (context, _) => DiscardChangesGuard(
        hasChanges: !_saving && (_volumeCtrl.text.trim().isNotEmpty || _expected != null || _actual != null),
        message: 'La cosecha no se registrará.',
        child: Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SimpleAppBar(title: 'Cosecha'),
      body: Form(
        key: _formKey,
        child: ResponsiveBody(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenH),
            children: [
              const SectionTitle('Fecha esperada'),
              const SizedBox(height: AppSpacing.sm),
              AppDateField(
                label: 'Fecha',
                value: _expected,
                firstDate: DateTime(now.year - 1),
                lastDate: DateTime(now.year + 2),
                errorText: _expectedError,
                onChanged: (d) => setState(() {
                  _expected = d;
                  _expectedError = null;
                }),
              ),
              const SizedBox(height: AppSpacing.xl),
              const SectionTitle('Fecha real'),
              const SizedBox(height: AppSpacing.sm),
              AppDateField(
                label: 'Fecha',
                optional: true,
                value: _actual,
                firstDate: DateTime(now.year - 1),
                lastDate: now,
                onChanged: (d) => setState(() => _actual = d),
              ),
              const SizedBox(height: AppSpacing.xl),
              const SectionTitle('Volumen'),
              const SizedBox(height: AppSpacing.sm),
              AppNumberField(
                label: 'Volumen cosechado (kilos)',
                controller: _volumeCtrl,
                hint: 'Ej. 850',
                decimals: 1,
                min: 0,
                unit: 'kg',
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
        PrimaryButton(
          label: 'Guardar cosecha',
          loadingLabel: 'Guardando...',
          isLoading: _saving,
          color: AppColors.primaryDark,
          onPressed: _save,
        ),
      ]),
        ),
      ),
    );
  }
}
