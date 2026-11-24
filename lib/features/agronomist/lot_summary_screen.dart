import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';
import '../../data/app_services.dart';
import '../../data/models/lot_summary.dart';
import '../../data/pdf_service.dart';
import '../../shared/shared.dart';
import 'agronomist_controller.dart';

/// Resumen fitosanitario del lote, con la tendencia del MTD y los indicadores.
/// Se consulta por [lotId]. Sin conexión muestra la última copia guardada en el teléfono
/// (con su fecha), o un error claro si nunca se consultó.
/// "Exportar resumen" genera un PDF en el dispositivo y abre el diálogo del
/// sistema para guardarlo, compartirlo o imprimirlo.
class LotSummaryScreen extends StatefulWidget {
  const LotSummaryScreen({super.key, this.lotId});

  /// Lote a consultar. Sin valor (entradas del agrónomo) se usa el lote seleccionado.
  final String? lotId;

  @override
  State<LotSummaryScreen> createState() => _LotSummaryScreenState();
}

class _LotSummaryScreenState extends State<LotSummaryScreen> {
  LotSummary? _summary;
  Object? _error;
  bool _loading = true;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final id =
          widget.lotId ?? await AgronomistController.instance.ensureLot();
      final resumen = await AppServices.agronomist.getLotSummary(id);
      if (mounted) setState(() => _summary = resumen);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _export() async {
    final resumen = _summary;
    if (resumen == null || _exporting) return;
    setState(() => _exporting = true);
    try {
      await PdfService.instance.exportLotSummary(resumen);
    } catch (e) {
      if (mounted) {
        AppMessenger.error('No se pudo generar el PDF',
            message: 'Intenta de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  static String _fechaHora(DateTime d) =>
      '${Fmt.date(d)} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final s = _summary;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SimpleAppBar(title: 'Resumen del lote'),
      body: _cuerpo(s),
      bottomNavigationBar: s == null
          ? null
          : BottomActions(children: [
              PrimaryButton(
                label:
                    _exporting ? 'Generando PDF...' : 'Exportar resumen (PDF)',
                icon: Icons.ios_share,
                isLoading: _exporting,
                color: AppColors.primaryDark,
                onPressed: _export,
              ),
            ]),
    );
  }

  Widget _cuerpo(LotSummary? s) {
    if (s == null) {
      if (_loading) return const AppLoader();
      return ErrorState(
          error: _error, what: 'el resumen del lote', onRetry: _cargar);
    }
    return ResponsiveBody(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenH),
        children: [
          if (s.cachedAt != null) ...[
            AlertBanner(
              type: AlertType.warning,
              title: 'Sin conexión',
              message:
                  'Mostrando el último resumen guardado el ${_fechaHora(s.cachedAt!)}.',
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

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
            KpiTile(
                label: 'Visitas realizadas',
                value: '${s.inspectionsThisMonth}',
                hint: 'Este mes'),
            KpiTile(label: 'Lecturas totales', value: '${s.readingsTotal}'),
            KpiTile(
                label: 'Especímenes detectados',
                value: '${s.specimensDetected}'),
            KpiTile(
                label: 'Trampas con hallazgos',
                value: '${s.trapsWithFindings} de ${s.trapsTotal}'),
          ]),
          const SizedBox(height: AppSpacing.lg),

          const SectionTitle('Cultivo'),
          const SizedBox(height: AppSpacing.sm),
          _grid([
            KpiTile(label: 'Etapa fenológica', value: s.phenologicalStage),
            KpiTile(
              label: 'Última aplicación',
              value: s.lastApplication == null
                  ? null
                  : Fmt.date(s.lastApplication!),
              hint: '${s.applications} registradas',
            ),
            KpiTile(
              label: 'Producción estimada',
              value: s.estimatedYieldKg == null
                  ? null
                  : '${Fmt.decimal(s.estimatedYieldKg!)} kg',
            ),
            KpiTile(
              label: 'Producción real',
              value: s.actualYieldKg == null
                  ? null
                  : '${Fmt.decimal(s.actualYieldKg!)} kg',
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
                s.activeFindings == 0
                    ? 'Ninguno'
                    : '${s.activeFindings} sin resolver',
                tone: s.activeFindings == 0
                    ? StatusTone.success
                    : StatusTone.warning,
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
          const Text(
              'Indicadores calculados por el servidor (la app no los deduce).',
              style: AppText.micro,
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  /// Dos columnas en móvil; se adapta solo al ancho disponible.
  Widget _grid(List<Widget> items) => LayoutBuilder(
        builder: (context, c) {
          final columnas = c.maxWidth > 520 ? 4 : 2;
          final ancho =
              (c.maxWidth - (columnas - 1) * AppSpacing.md) / columnas;
          return Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [for (final i in items) SizedBox(width: ancho, child: i)],
          );
        },
      );
}
