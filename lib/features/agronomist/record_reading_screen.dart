import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';
import '../../data/app_services.dart';
import '../../data/models/reading.dart';
import '../../data/models/trap.dart';
import '../../shared/shared.dart';

/// Lectura registrada de una trampa. El agrónomo la CONSULTA: no la edita.
class RecordReadingScreen extends StatefulWidget {
  const RecordReadingScreen({super.key, required this.trapId});
  final String trapId;

  @override
  State<RecordReadingScreen> createState() => _RecordReadingScreenState();
}

class _RecordReadingScreenState extends State<RecordReadingScreen> {
  late Future<(Trap, Reading?)> _future = _load();

  /// Trampa y su última lectura recibida por el servidor.
  Future<(Trap, Reading?)> _load() => AppServices.agronomist.trapWithLastReading(widget.trapId);

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SimpleAppBar(title: 'Lectura de Trampa'),
      body: FutureBuilder<(Trap, Reading?)>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) return ErrorState(error: snap.error, what: 'la lectura', onRetry: _reload);
          if (!snap.hasData) return const AppLoader();
          final (trampa, lectura) = snap.data!;
          if (lectura == null) {
            return EmptyState(
              icon: Icons.inbox_outlined,
              title: 'Sin lecturas registradas',
              message: 'La trampa ${trampa.label} todavía no tiene lecturas en el servidor.',
              action: SecondaryButton(label: 'Volver', onPressed: () => Navigator.of(context).pop()),
            );
          }
          return ResponsiveBody(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screenH),
              children: [
                TrapHeaderCard(code: trampa.label, subtitle: trampa.icaCode),
                const SizedBox(height: AppSpacing.lg),
                ReadOnlyField(
                  label: 'Fecha de observación',
                  value: '${Fmt.dateNumeric(lectura.observedAt)}   ·   ${Fmt.time(lectura.observedAt)}',
                ),
                const SizedBox(height: AppSpacing.md),
                ReadOnlyField(label: 'Número de especímenes', value: '${lectura.specimens}'),
                const SizedBox(height: AppSpacing.md),
                ReadOnlyField(label: 'Estado de la trampa', value: lectura.condition.label),
                const SizedBox(height: AppSpacing.md),
                ReadOnlyField(
                  label: 'Observaciones',
                  value: lectura.observations?.isNotEmpty == true ? lectura.observations! : 'Sin descripción',
                ),
                if (lectura.evidence.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  FieldLabel('Evidencias (${lectura.evidence.length})'),
                ],
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomActions(children: [
        PrimaryButton(
          label: 'Volver',
          color: AppColors.primaryDark,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ]),
    );
  }
}
