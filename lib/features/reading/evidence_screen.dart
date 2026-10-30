import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';
import '../../data/models/photo_file.dart';
import '../../data/models/reading.dart';
import '../../shared/shared.dart';

/// Resultado de la pantalla de evidencia.
/// `changeSource` = la persona quiere elegir otra foto.
class EvidenceResult {
  const EvidenceResult({this.evidence, this.changeSource = false});
  final Evidence? evidence;
  final bool changeSource;
}

/// M05-T — Vista previa de la evidencia + observación + "Subir foto".
/// Recibe una foto YA validada por `PhotoService`.
class EvidenceScreen extends StatefulWidget {
  const EvidenceScreen({super.key, required this.photo});
  final PhotoFile photo;

  @override
  State<EvidenceScreen> createState() => _EvidenceScreenState();
}

class _EvidenceScreenState extends State<EvidenceScreen> {
  final _obsCtrl = TextEditingController();

  @override
  void dispose() {
    _obsCtrl.dispose();
    super.dispose();
  }

  void _confirm() {
    Navigator.of(context).pop(EvidenceResult(
      evidence: Evidence.fromPhoto(
        widget.photo,
        id: 'ev-${DateTime.now().microsecondsSinceEpoch}',
        observation: _obsCtrl.text.trim(),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SimpleAppBar(title: 'Evidencia'),
      body: ResponsiveBody(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenH),
          children: [
            PhotoPreview(photo: widget.photo),
            const SizedBox(height: AppSpacing.sm),
            PhotoMetaLine(widget.photo),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Observaciones',
              controller: _obsCtrl,
              hint: 'Ej. Fruto afectado, trampa dañada, punto de referencia...',
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.lg),
            const AlertBanner(
              type: AlertType.info,
              title: 'La fotografía se guarda en el dispositivo',
              message: 'Se enviará al servidor cuando la sincronización esté disponible.',
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActions(children: [
        PrimaryButton(label: 'Subir foto', color: AppColors.primaryDark, onPressed: _confirm),
        SecondaryButton(
          label: 'Tomar o elegir otra',
          icon: Icons.refresh,
          onPressed: () => Navigator.of(context).pop(const EvidenceResult(changeSource: true)),
        ),
      ]),
    );
  }
}
