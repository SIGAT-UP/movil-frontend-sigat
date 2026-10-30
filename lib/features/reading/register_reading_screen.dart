import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/routes.dart';
import '../../app/shell_nav.dart';
import '../../core/widgets/widgets.dart';
import '../../data/app_services.dart';
import '../../data/models/photo_file.dart';
import '../../data/models/reading.dart';
import '../../data/models/trap.dart';
import '../../data/photo_service.dart';
import '../../shared/shared.dart';
import '../visit/visit_controller.dart';
import 'evidence_screen.dart';

/// M05-T — Registrar lectura (+ estado "Lectura guardada").
class RegisterReadingScreen extends StatefulWidget {
  const RegisterReadingScreen({super.key, required this.trap});
  final Trap trap;

  @override
  State<RegisterReadingScreen> createState() => _RegisterReadingScreenState();
}

class _RegisterReadingScreenState extends State<RegisterReadingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _specimensCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();

  DateTime _observedDate = DateTime.now();
  final DateTime _openedAt = DateTime.now(); // hora automática
  TrapCondition _condition = TrapCondition.buenEstado;
  DateTime? _bodyChange;
  DateTime? _attractantChange;
  final List<Evidence> _evidence = [];

  bool _saving = false;
  bool _saved = false;

  @override
  void dispose() {
    _specimensCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  /// "Adjuntar evidencia": elegir origen → validar → previsualizar → confirmar.
  /// Si la persona pide otra foto, vuelve a abrir el selector de origen.
  /// Cancelar en cualquier paso no modifica el formulario.
  Future<void> _addEvidence() async {
    while (mounted) {
      final choice = await showPhotoSourceSheet(
        context,
        title: 'Adjuntar evidencia',
        message: 'Fotografía de la trampa o del daño observado.',
        isWeb: PhotoService.instance.cameraIsFilePickerOnWeb,
      );
      if (choice == null || !mounted) return; // canceló

      final source = choice == PhotoSourceChoice.camara ? PhotoSource.camara : PhotoSource.galeria;
      PhotoFile? photo;
      try {
        photo = await PhotoService.instance.pick(source);
      } on PhotoException catch (e) {
        if (!mounted) return;
        _showError(e.message);
        continue; // deja reintentar sin salir del flujo
      }
      if (photo == null || !mounted) return; // canceló la cámara o la galería

      final result = await Navigator.of(context).pushNamed(AppRoutes.evidence, arguments: photo);
      if (!mounted) return;
      if (result is EvidenceResult) {
        if (result.changeSource) continue; // quiere elegir otra foto
        if (result.evidence != null) {
          setState(() => _evidence.add(result.evidence!));
          return;
        }
      }
      return; // volvió atrás sin confirmar
    }
  }

  Future<void> _removeEvidence(int index) async {
    final ok = await showAppConfirmDialog(
      context,
      title: 'Quitar evidencia',
      message: 'Se descartará esta fotografía. Los demás datos del formulario se conservan.',
      confirmLabel: 'Quitar',
      destructive: true,
    );
    if (ok && mounted) setState(() => _evidence.removeAt(index));
  }

  void _showError(String message) => AppMessenger.error('No se pudo adjuntar la evidencia', message: message);

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final visit = VisitController.instance;
    final observedAt = DateTime(
        _observedDate.year, _observedDate.month, _observedDate.day, _openedAt.hour, _openedAt.minute);
    final readingId = 'r-${DateTime.now().microsecondsSinceEpoch}';
    // Cada evidencia queda relacionada con ESTA lectura, su trampa y su lote.
    final evidencias = [
      for (final e in _evidence)
        e.attachTo(
          readingId: readingId,
          trapId: widget.trap.id,
          lotId: widget.trap.lotId,
          userId: AppServices.session.value?.userId,
        ),
    ];
    try {
      await visit.saveReading(Reading(
        id: readingId,
        trapId: widget.trap.id,
        trapLabel: widget.trap.label,
        lotId: widget.trap.lotId,
        observedAt: observedAt,
        specimens: int.parse(_specimensCtrl.text),
        condition: _condition,
        bodyChangeDate: _bodyChange,
        attractantChangeDate: _attractantChange,
        observations: _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
        evidence: evidencias,
      ));
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saved = true;
      });
      // Se muestra "Lectura guardada" un momento y luego pasa a Visita en curso.
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      if (mounted) ShellNav.goTo(context, AppTab.visita);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppMessenger.error('No se pudo guardar la lectura', message: 'Revisa los datos e intenta de nuevo.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lot = VisitController.instance.activeLot;
    // Si hay datos sin guardar, el botón atrás pregunta antes de salir.
    return ListenableBuilder(
      listenable: Listenable.merge([_specimensCtrl, _obsCtrl]),
      builder: (context, _) => DiscardChangesGuard(
        hasChanges: !_saved &&
              (_specimensCtrl.text.trim().isNotEmpty ||
                  _obsCtrl.text.trim().isNotEmpty ||
                  _evidence.isNotEmpty ||
                  _bodyChange != null ||
                  _attractantChange != null),
        message: 'La lectura y las evidencias que adjuntaste no se guardarán.',
        child: Scaffold(
      appBar: const SimpleAppBar(title: 'Registrar lectura', actions: [LocalStorageBadge()]),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenH),
          children: [
            TrapHeaderCard(code: widget.trap.label, subtitle: lot == null ? widget.trap.icaCode : '${lot.name} · ${lot.crop}'),
            const SizedBox(height: AppSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppDateField(
                    label: 'Fecha de observación',
                    value: _observedDate,
                    lastDate: DateTime.now(),
                    onChanged: (d) => setState(() => _observedDate = d ?? DateTime.now()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: ReadOnlyField(label: 'Hora (automática)', value: Fmt.time(_openedAt))),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Número de especímenes',
              controller: _specimensCtrl,
              hint: '0',
              keyboardType: TextInputType.number,
              enabled: !_saved,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Ingresa el número de especímenes (0 si no hay)';
                if (int.tryParse(v) == null) return 'Solo números enteros';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppDropdownField<TrapCondition>(
              label: 'Estado de la trampa',
              value: _condition,
              items: TrapCondition.values,
              itemLabel: (c) => c.label,
              onChanged: (c) => setState(() => _condition = c),
            ),
            const SizedBox(height: AppSpacing.md),
            AppDateField(
              label: 'Fecha de cambio del cuerpo',
              optional: true,
              value: _bodyChange,
              onChanged: (d) => setState(() => _bodyChange = d),
            ),
            const SizedBox(height: AppSpacing.md),
            AppDateField(
              label: 'Fecha de cambio del atrayente',
              optional: true,
              value: _attractantChange,
              onChanged: (d) => setState(() => _attractantChange = d),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Observaciones',
              controller: _obsCtrl,
              hint: 'Escribe una observación (opcional)',
              maxLines: 2,
              enabled: !_saved,
            ),
            if (_evidence.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              FieldLabel('Evidencias (${_evidence.length})'),
              SizedBox(
                height: 84,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _evidence.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => _EvidenceThumb(
                    evidence: _evidence[i],
                    onRemove: _saved ? null : () => _removeEvidence(i),
                  ),
                ),
              ),
            ],
            ValueListenableBuilder<bool>(
              valueListenable: AppServices.isOnline,
              builder: (_, online, __) => online
                  ? const SizedBox.shrink()
                  : const Padding(
                      padding: EdgeInsets.only(top: AppSpacing.lg),
                      child: AlertBanner(
                        type: AlertType.info,
                        title: 'Sin conexión — los datos se guardarán en el dispositivo.',
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActions(children: [
        if (_saved)
          const SuccessToastBar('Lectura guardada')
        else
          PrimaryButton(
            label: 'Adjuntar evidencia',
            icon: Icons.photo_camera_outlined,
            color: AppColors.primaryDark,
            onPressed: _saving ? null : _addEvidence,
          ),
        PrimaryButton(
          label: 'Guardar lectura',
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

class _EvidenceThumb extends StatelessWidget {
  const _EvidenceThumb({required this.evidence, this.onRemove});
  final Evidence evidence;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 84,
            height: 84,
            child: evidence.bytes == null
                ? const ColoredBox(color: AppColors.surface, child: Icon(Icons.image_outlined))
                : Image.memory(evidence.bytes!, fit: BoxFit.cover, gaplessPlayback: true),
          ),
        ),
        Positioned(
          left: 2,
          bottom: 2,
          child: RecordStatusBadge(
            evidence.uploadStatus == UploadStatus.uploaded ? RecordStatus.enviado : RecordStatus.local,
            label: evidence.uploadStatus == UploadStatus.uploaded ? 'Enviada' : 'En equipo',
          ),
        ),
        if (onRemove != null)
          Positioned(
            right: 2,
            top: 2,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                onRemove!();
              },
              child: const CircleAvatar(
                radius: 11,
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
