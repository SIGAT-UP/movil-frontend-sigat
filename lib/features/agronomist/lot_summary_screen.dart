import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';
import '../../data/pdf_service.dart';
import '../../shared/shared.dart';
import 'agronomist_controller.dart';

/// Resumen fitosanitario del lote, con la tendencia del MTD y los indicadores.
/// "Exportar resumen" genera un PDF en el dispositivo y abre el diálogo del
/// sistema para guardarlo, compartirlo o imprimirlo.
class LotSummaryScreen extends StatefulWidget {
  const LotSummaryScreen({super.key});

  @override
  State<LotSummaryScreen> createState() => _LotSummaryScreenState();
}

class _LotSummaryScreenState extends State<LotSummaryScreen> {
  final _ctrl = AgronomistController.instance;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    if (_ctrl.summary == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ctrl.load());
    }
  }

  Future<void> _export() async {
    final resumen = _ctrl.summary;
    if (resumen == null || _exporting) return;
    setState(() => _exporting = true);
    try {
      await PdfService.instance.exportLotSummary(resumen);
    } catch (e) {
      if (mounted) {
        AppMessenger.error('No se pudo generar el PDF', message: 'Intenta de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SimpleAppBar(title: 'Resumen del lote'),
      body: ListenableBuilder(
        listenable: _ctrl,
        builder: (context, _) {
          final s = _ctrl.summary;
          if (s == null && _ctrl.loadError != null && !_ctrl.loading) {
            return ErrorState(error: _ctrl.loadError, what: 'el resumen del lote', onRetry: _ctrl.load);
          }
          if (s == null) return const AppLoader();
          return ResponsiveBody(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screenH),
              children: [
                // --- Identificación ---
                AppCard(
                  tone: AppCardTone.highlighted,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.lotName, style: AppText.h2),
                      const SizedBox(height: 2),
                      Text(
                        '${s.trapsTotal} trampas · última visita '
                        '${s.lastVisit == null ? 'sin registrar' : Fmt.date(s.lastVisit!)}',
                        style: AppText.secondary,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text('Escenario: ${s.scenario.toLowerCase()}',
                          style: AppText.h3.copyWith(color: AppColors.primaryDark)),
                      Text(
                        'MTD ${s.mtd == null ? 'sin cálculo' : Fmt.fixed(s.mtd!, 2)} · '
                        'Umbral de exportación: ${s.exportThreshold.toLowerCase()} · '
                        'Concepto: ${s.aptitudeConcept.toLowerCase()}',
                        style: AppText.caption,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // --- Tendencia del MTD ---
                const SectionTitle('Tendencia del MTD'),
                const SizedBox(height: AppSpacing.sm),
                AppCard(
                  child: MtdChart(series: s.series, limit: s.scenarioLimit),
                ),
                const SizedBox(height: AppSpacing.lg),

                // --- Indicadores ---
                const SectionTitle('Vigilancia'),
                const SizedBox(height: AppSpacing.sm),
                _grid([
                  KpiTile(label: 'Visitas realizadas', value: '${s.inspectionsThisMonth}', hint: 'Este mes'),
                  KpiTile(label: 'Lecturas totales', value: '${s.readingsTotal}'),
                  KpiTile(label: 'Especímenes detectados', value: '${s.specimensDetected}'),
                  KpiTile(label: 'Trampas con hallazgos', value: '${s.trapsWithFindings} de ${s.trapsTotal}'),
                ]),
                const SizedBox(height: AppSpacing.lg),

                const SectionTitle('Cultivo'),
                const SizedBox(height: AppSpacing.sm),
                _grid([
                  KpiTile(label: 'Etapa fenológica', value: s.phenologicalStage),
                  KpiTile(
                    label: 'Última aplicación',
                    value: s.lastApplication == null ? null : Fmt.date(s.lastApplication!),
                    hint: '${s.applications} registradas',
                  ),
                  KpiTile(
                    label: 'Producción estimada',
                    value: s.estimatedYieldKg == null ? null : '${Fmt.decimal(s.estimatedYieldKg!)} kg',
                  ),
                  KpiTile(
                    label: 'Producción real',
                    value: s.actualYieldKg == null ? null : '${Fmt.decimal(s.actualYieldKg!)} kg',
                    hint: s.actualYieldKg == null ? 'Pendiente de cosecha' : null,
                  ),
                ]),
                const SizedBox(height: AppSpacing.lg),

                // --- BPA y hallazgos ---
                InfoTableCard(rows: [
                  InfoRowData(
                    'Buenas prácticas (BPA)',
                    trailing: StatusBadge(s.goodPracticesLabel, icon: Icons.check),
                  ),
                  InfoRowData(
                    'Hallazgos vigentes',
                    trailing: StatusBadge(
                      s.activeFindings == 0 ? 'Ninguno' : '${s.activeFindings} sin resolver',
                      tone: s.activeFindings == 0 ? StatusTone.success : StatusTone.warning,
                    ),
                  ),
                ]),

                if (s.pendingReviewLabel != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  AlertBanner(
                    type: AlertType.warning,
                    title: '1 registro por revisar',
                    message: s.pendingReviewLabel,
                  ),
                ],

                const SizedBox(height: AppSpacing.lg),
                const Text('Indicadores calculados por el servidor (la app no los deduce).',
                    style: AppText.micro, textAlign: TextAlign.center),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomActions(children: [
        PrimaryButton(
          label: _exporting ? 'Generando PDF...' : 'Exportar resumen (PDF)',
          icon: Icons.ios_share,
          isLoading: _exporting,
          color: AppColors.primaryDark,
          onPressed: _export,
        ),
      ]),
    );
  }

  /// Dos columnas en móvil; se adapta solo al ancho disponible.
  Widget _grid(List<Widget> items) => LayoutBuilder(
        builder: (context, c) {
          final columnas = c.maxWidth > 520 ? 4 : 2;
          final ancho = (c.maxWidth - (columnas - 1) * AppSpacing.md) / columnas;
          return Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [for (final i in items) SizedBox(width: ancho, child: i)],
          );
        },
      );
}
