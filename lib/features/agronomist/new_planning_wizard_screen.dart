import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';
import '../../data/app_services.dart';
import '../../data/document_service.dart';
import '../../data/models/photo_file.dart';
import '../../data/models/planning.dart';
import '../../shared/shared.dart';
import 'agronomist_controller.dart';

/// Asistente de 3 pasos para crear una planificación.
///
/// Un solo asistente para los dos casos; solo cambia el paso 2:
///  * Técnico   → Datos · Lotes · Confirmación
///  * Productor → Datos · Instrucciones · Confirmación
///
/// Los datos escritos se conservan al ir y volver entre pasos.
///
/// Si llega `from` (por ejemplo, "Crear nueva planificación" después de un
/// rechazo), el asistente arranca con el mismo destinatario, la misma
/// actividad, los mismos lotes y las mismas observaciones. Las fechas se
/// dejan vacías a propósito: casi siempre son lo que hay que cambiar.
class NewPlanningWizardScreen extends StatefulWidget {
  const NewPlanningWizardScreen({super.key, required this.target, this.from});
  final PlanningTarget target;
  final Planning? from;

  @override
  State<NewPlanningWizardScreen> createState() => _NewPlanningWizardScreenState();
}

class _NewPlanningWizardScreenState extends State<NewPlanningWizardScreen> {
  final _ctrl = AgronomistController.instance;

  bool get _esTecnico => widget.target == PlanningTarget.tecnico;

  int _step = 0;
  String _search = '';

  // Paso 1
  Recipient? _recipient;
  final _activityCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String? _dateError;

  // Paso 2
  final Set<String> _lots = {};
  String? _lotsError;
  PlanningDoc? _attachment;

  /// Planeación a productor: hace falta el documento de instrucciones; si no
  /// se sube, la observación pasa a ser obligatoria (con un mínimo de texto).
  static const _minObservacion = 10;
  String? _instructionsError;

  bool get _instruccionesCompletas =>
      _attachment != null || _obsCtrl.text.trim().length >= _minObservacion;
  bool _picking = false;

  // Paso 3
  final _obsCtrl = TextEditingController();

  late final Future<List<Recipient>> _recipients = AppServices.plannings.getRecipients(widget.target);
  late final Future<List<String>> _assignableLots = AppServices.plannings.getAssignableLots();

  @override
  void initState() {
    super.initState();
    final base = widget.from;
    if (base != null) {
      _recipient = Recipient(id: base.recipientId, name: base.recipientName, target: base.target);
      _activityCtrl.text = base.activity;
      _lots.addAll(base.lotNames);
      _obsCtrl.text = base.observations ?? '';
      _attachment = base.doc;
    } else {
      _activityCtrl.text = _esTecnico ? 'Muestreo de cultivos' : 'Actividades de riego y revisión';
    }
  }

  @override
  void dispose() {
    _activityCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  // ---------------- botón atrás ----------------

  /// ¿Hay algo escrito o elegido que se perdería al salir?
  bool get _hasChanges =>
      _step > 0 ||
      (widget.from == null && _recipient != null) ||
      _startDate != null ||
      _endDate != null ||
      (widget.from == null && _lots.isNotEmpty) ||
      (widget.from == null && _attachment != null) ||
      (widget.from == null && _obsCtrl.text.trim().isNotEmpty);

  /// Atrás (barra o sistema): en los pasos 2 y 3 vuelve al anterior; en el
  /// primero sale, preguntando antes si hay algo que se perdería.
  Future<void> _onBack() async {
    if (_step > 0) {
      setState(() {
        _step--;
        _search = '';
      });
      return;
    }
    final salir = await showAppConfirmDialog(
      context,
      title: '¿Salir sin guardar?',
      message: _esTecnico
          ? 'La asignación no se guardará.'
          : 'La planeación no se guardará.',
      confirmLabel: 'Salir sin guardar',
      cancelLabel: 'Seguir editando',
      destructive: true,
    );
    if (salir && mounted) Navigator.of(context).pop();
  }

  // ---------------- validación por paso ----------------

  bool _validateStep1() {
    final sinPersona = _recipient == null;
    final sinFecha = _startDate == null;
    final fechasAlReves = _startDate != null && _endDate != null && _endDate!.isBefore(_startDate!);
    setState(() {
      _dateError = sinFecha
          ? 'Selecciona la fecha de asignación'
          : (fechasAlReves ? 'La fecha de finalización no puede ser anterior a la de inicio' : null);
    });
    if (sinPersona) {
      AppMessenger.warning(_esTecnico ? 'Selecciona un técnico' : 'Selecciona un productor');
      return false;
    }
    if (_activityCtrl.text.trim().isEmpty) {
      AppMessenger.warning('Escribe la actividad');
      return false;
    }
    return !sinFecha && !fechasAlReves;
  }

  bool _validateStep2() {
    if (_esTecnico) {
      setState(() => _lotsError = _lots.isEmpty ? 'Selecciona al menos un lote' : null);
      if (_lots.isEmpty) {
        AppMessenger.warning('Selecciona al menos un lote');
        return false;
      }
    }
    if (!_esTecnico && !_instruccionesCompletas) {
      final sinTexto = _obsCtrl.text.trim().isEmpty;
      setState(() => _instructionsError = sinTexto
          ? 'Sube el documento de instrucciones o, si no lo tienes, escribe una observación.'
          : 'La observación debe tener al menos $_minObservacion caracteres.');
      AppMessenger.warning('Faltan las instrucciones', message: _instructionsError);
      return false;
    }
    setState(() => _instructionsError = null);
    return true;
  }

  void _next() {
    if (_step == 0 && !_validateStep1()) return;
    if (_step == 1 && !_validateStep2()) return;
    if (_step < 2) {
      setState(() {
        _step++;
        _search = ''; // cada paso busca en su propia lista
      });
      return;
    }
    _save();
  }

  /// Dos orígenes: documento (PDF o Word) o imagen de la galería. Sin cámara.
  Future<void> _attach() async {
    if (_picking) return;
    final choice = await showDocumentSourceSheet(context, allowRemove: _attachment != null);
    if (choice == null || !mounted) return;
    if (choice == DocumentSourceChoice.quitar) {
      setState(() => _attachment = null);
      return;
    }
    setState(() => _picking = true);
    try {
      final doc = choice == DocumentSourceChoice.documento
          ? await DocumentService.instance.pickDocument()
          : await DocumentService.instance.pickImage();
      if (doc != null && mounted) {
        setState(() {
          _attachment = doc;
          _instructionsError = null;
        });
      }
    } on DocumentException catch (e) {
      if (mounted) AppMessenger.warning('No se puede usar ese archivo', message: e.message);
    } on PhotoException catch (e) {
      if (mounted) AppMessenger.warning('No se puede usar esa imagen', message: e.message);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _save() async {
    final r = _recipient!;
    final doc = _attachment;

    final nueva = Planning(
      id: 'pl-${DateTime.now().microsecondsSinceEpoch}',
      target: widget.target,
      recipientId: r.id,
      recipientName: r.name,
      activity: _activityCtrl.text.trim(),
      startDate: _startDate!,
      endDate: _endDate,
      lotNames: _lots.toList()..sort(),
      observations: _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
      doc: doc,
      createdAt: DateTime.now(),
      createdByName: AppServices.session.value?.displayName ?? '',
    );

    final ok = await _ctrl.createPlanning(nueva);
    if (!mounted) return;
    if (ok) {
      AppMessenger.success(
        _esTecnico ? 'Asignación guardada' : 'Planeación guardada',
        message: 'Quedó pendiente de respuesta de ${r.name}.',
      );
      Navigator.of(context).pop();
    } else {
      AppMessenger.error('No se pudo guardar', message: _ctrl.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pasos = _esTecnico
        ? ['Datos', 'Lotes', 'Confirmación']
        : ['Datos', 'Instrucciones', 'Confirmación'];

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
      backgroundColor: AppColors.surface,
      appBar: SimpleAppBar(title: _esTecnico ? 'Nueva asignación' : 'Nueva planeación'),
      body: ResponsiveBody(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenH, AppSpacing.lg, AppSpacing.screenH, AppSpacing.lg),
              child: WizardSteps(labels: pasos, current: _step),
            ),
            Expanded(
              child: switch (_step) {
                0 => _paso1(),
                1 => _esTecnico ? _paso2Lotes() : _paso2Instrucciones(),
                _ => _paso3(),
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: _ctrl,
        builder: (context, _) => WizardActions(
          nextLabel: _step < 2 ? 'Siguiente' : (_esTecnico ? 'Guardar asignación' : 'Guardar planeación'),
          isLoading: _ctrl.busy,
          onBack: _step == 0 ? null : _onBack,
          onNext: _next,
        ),
      ),
      ),
    );
  }

  // ---------------- paso 1: datos ----------------

  Widget _paso1() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, 0, AppSpacing.screenH, AppSpacing.xl),
      children: [
        Text(_esTecnico ? 'Seleccionar el técnico' : 'Seleccionar el productor', style: AppText.label),
        const SizedBox(height: AppSpacing.sm),
        AppSearchField(
          hint: _esTecnico ? 'Buscar técnico...' : 'Buscar productor...',
          onChanged: (v) => setState(() => _search = v),
        ),
        const SizedBox(height: AppSpacing.md),
        FutureBuilder<List<Recipient>>(
          future: _recipients,
          builder: (context, snap) {
            if (snap.hasError) return ErrorState(error: snap.error, what: 'los destinatarios');
            if (!snap.hasData) return const AppLoader(padding: EdgeInsets.all(AppSpacing.lg));
            final q = _search.trim().toLowerCase();
            final lista = snap.data!.where((r) => r.name.toLowerCase().contains(q)).toList();
            if (lista.isEmpty) {
              return const EmptyState(icon: Icons.person_search, title: 'Sin resultados');
            }
            return Column(
              children: [
                for (final r in lista)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: SelectableTile(
                      title: r.name,
                      subtitle: _esTecnico ? 'Técnico' : 'Productor',
                      avatarName: r.name,
                      selected: _recipient?.id == r.id,
                      onTap: () => setState(() => _recipient = r),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: 'Actividad',
          controller: _activityCtrl,
          hint: 'Ej. Muestreo de cultivos',
        ),
        const SizedBox(height: AppSpacing.lg),
        const Text('Seleccionar la fecha de asignación', style: AppText.label),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppDateField(
                label: 'Fecha de inicio',
                value: _startDate,
                errorText: _dateError,
                onChanged: (d) => setState(() {
                  _startDate = d;
                  _dateError = null;
                }),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppDateField(
                label: 'Fecha de finalización',
                optional: true,
                value: _endDate,
                onChanged: (d) => setState(() => _endDate = d),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------- paso 2 (técnico): lotes ----------------

  Widget _paso2Lotes() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, 0, AppSpacing.screenH, AppSpacing.xl),
      children: [
        AppSearchField(hint: 'Buscar lote...', onChanged: (v) => setState(() => _search = v)),
        const SizedBox(height: AppSpacing.md),
        if (_lotsError != null) ...[
          AlertBanner(title: _lotsError!),
          const SizedBox(height: AppSpacing.md),
        ],
        FutureBuilder<List<String>>(
          future: _assignableLots,
          builder: (context, snap) {
            if (snap.hasError) return ErrorState(error: snap.error, what: 'los lotes asignables');
            if (!snap.hasData) return const AppLoader(padding: EdgeInsets.all(AppSpacing.lg));
            final q = _search.trim().toLowerCase();
            final lista = snap.data!.where((l) => l.toLowerCase().contains(q)).toList();
            if (lista.isEmpty) {
              return const EmptyState(icon: Icons.search_off, title: 'Sin resultados');
            }
            return Column(
              children: [
                for (final l in lista)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: SelectableTile(
                      title: l,
                      multiple: true,
                      selected: _lots.contains(l),
                      onTap: () => setState(() {
                        _lots.contains(l) ? _lots.remove(l) : _lots.add(l);
                        _lotsError = null;
                      }),
                    ),
                  ),
              ],
            );
          },
        ),
        if (_lots.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text('${_lots.length} lote(s) seleccionado(s)', style: AppText.caption),
        ],
      ],
    );
  }

  // ---------------- paso 2 (productor): instrucciones ----------------

  Widget _paso2Instrucciones() {
    final sinDocumento = _attachment == null;
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, 0, AppSpacing.screenH, AppSpacing.xl),
      children: [
        if (_instructionsError != null) ...[
          AlertBanner(title: 'Faltan las instrucciones', message: _instructionsError),
          const SizedBox(height: AppSpacing.md),
        ],
        AppCard(
          borderColor: _instructionsError != null && sinDocumento ? AppColors.errorBorder : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Subir documento (instrucciones)', style: AppText.h3, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.lg),
              if (_attachment == null) ...[
                Center(
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                    child: const Icon(Icons.upload_file_outlined, size: 42, color: AppColors.primaryDark),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SecondaryButton(
                  label: _picking ? 'Abriendo...' : 'Seleccionar archivo',
                  icon: Icons.attach_file,
                  onPressed: _picking ? null : _attach,
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Documento PDF o Word, o una imagen de la galería. Obligatorio: si no '
                  'lo tienes, escribe una observación abajo.',
                  textAlign: TextAlign.center,
                  style: AppText.micro,
                ),
              ] else ...[
                if (_attachment!.kind == DocKind.imagen && _attachment!.bytes != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: Container(
                        color: AppColors.surface,
                        child: Image.memory(_attachment!.bytes!, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                DocumentCard(doc: _attachment),
                const SizedBox(height: AppSpacing.md),
                SecondaryButton(
                  label: 'Cambiar o quitar',
                  icon: Icons.swap_horiz,
                  onPressed: _picking ? null : _attach,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Sin documento, la observación es obligatoria; con documento, opcional.
        AppTextField(
          label: sinDocumento ? 'Observación (obligatoria sin documento)' : 'Observaciones (opcional)',
          controller: _obsCtrl,
          hint: sinDocumento
              ? 'Explica las instrucciones o por qué no hay documento'
              : 'Escribe aquí',
          maxLines: 3,
          hasError: _instructionsError != null && sinDocumento,
          helper: sinDocumento ? 'Mínimo $_minObservacion caracteres.' : null,
          onChanged: (_) {
            if (_instructionsError != null && _instruccionesCompletas) {
              setState(() => _instructionsError = null);
            }
          },
        ),
        const SizedBox(height: AppSpacing.md),
        const AlertBanner(
          type: AlertType.info,
          title: 'El archivo queda en este dispositivo',
          message: 'Se enviará al servidor cuando esté conectado. Mientras tanto, solo se '
              'puede ver desde este teléfono.',
        ),
      ],
    );
  }

  // ---------------- paso 3: confirmación ----------------

  Widget _paso3() {
    final r = _recipient!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, 0, AppSpacing.screenH, AppSpacing.xl),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_esTecnico ? 'Resumen de asignación' : 'Resumen de planeación', style: AppText.h3),
              const SizedBox(height: AppSpacing.md),
              _fila(Icons.person_outline, _esTecnico ? 'Técnico' : 'Productor', r.name),
              _fila(Icons.event_outlined, 'Periodo',
                  _endDate == null
                      ? Fmt.date(_startDate!)
                      : '${Fmt.dayMonth(_startDate!)} – ${Fmt.date(_endDate!)}'
                          '${_endDate!.difference(_startDate!).inDays > 0 ? ' · ${_endDate!.difference(_startDate!).inDays} días' : ''}'),
              _fila(Icons.task_alt, 'Actividad', _activityCtrl.text.trim()),
              if (_esTecnico)
                _fila(Icons.eco_outlined, 'Lotes', (_lots.toList()..sort()).join(', '))
              else ...[
                _fila(Icons.description_outlined, 'Documento',
                    _attachment == null
                        ? 'Sin documento adjunto'
                        : '${_attachment!.fileName} · ${_attachment!.detailLabel}'),
                _fila(Icons.notes_outlined, 'Observaciones',
                    _obsCtrl.text.trim().isEmpty ? 'Sin observaciones' : _obsCtrl.text.trim()),
              ],
            ],
          ),
        ),
        if (_esTecnico) ...[
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Observaciones (opcional)',
            controller: _obsCtrl,
            hint: 'Escribe aquí',
            maxLines: 3,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        AlertBanner(
          type: AlertType.info,
          title: _esTecnico ? 'Al guardar quedará asignada' : 'Al guardar quedará pendiente de respuesta',
          message: _esTecnico
              ? '${r.name} verá la actividad ya autorizada y se completa al terminar sus visitas en los lotes.'
              : '${r.name} podrá aceptarla o rechazarla desde su aplicación.',
        ),
      ],
    );
  }

  Widget _fila(IconData icono, String etiqueta, String valor) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
              child: Icon(icono, size: 16, color: AppColors.primaryDark),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(etiqueta, style: AppText.micro),
                  Text(valor.isEmpty ? 'Sin registrar' : valor, style: AppText.bodySmStrong),
                ],
              ),
            ),
          ],
        ),
      );
}
