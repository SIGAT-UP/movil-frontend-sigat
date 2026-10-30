import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';
import 'agronomist_controller.dart';
import '../../shared/shared.dart';

/// Configuración vigente del lote: programa de inspección y escenarios de
/// trampeo. Es de CONSULTA: la edición se hace en el cliente web.
class AgronomistConfigScreen extends StatefulWidget {
  const AgronomistConfigScreen({super.key});

  @override
  State<AgronomistConfigScreen> createState() => _AgronomistConfigScreenState();
}

class _AgronomistConfigScreenState extends State<AgronomistConfigScreen> {
  final _ctrl = AgronomistController.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ctrl.loadConfig());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SimpleAppBar(title: 'Configuración'),
      body: ListenableBuilder(
        listenable: _ctrl,
        builder: (context, _) {
          final c = _ctrl.config;
          if (c == null && _ctrl.configError != null) {
            return ErrorState(error: _ctrl.configError, what: 'el programa de inspección', onRetry: _ctrl.loadConfig);
          }
          if (c == null) return const AppLoader();
          return ResponsiveBody(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screenH),
              children: [
                InfoTableCard(
                  title: 'Programa de inspección',
                  rows: [
                    InfoRowData('Periodo de lectura', value: '${c.readingPeriodDays} días'),
                    InfoRowData('Trampas configuradas', value: '${c.trapsConfigured}'),
                    InfoRowData('Verificación', value: c.verification),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                const SectionTitle('Escenarios de trampeo (Tabla 1)'),
                const SizedBox(height: AppSpacing.sm),
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 4),
                  child: Column(
                    children: [
                      for (var i = 0; i < c.scenarios.length; i++) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c.scenarios[i].name, style: AppText.bodySmStrong),
                                    Text(c.scenarios[i].rule, style: AppText.micro),
                                  ],
                                ),
                              ),
                              if (c.scenarios[i].isCurrent)
                                const StatusBadge('Actual', icon: Icons.check)
                              else if (c.scenarios[i].pending)
                                const StatusBadge('Por definir',
                                    tone: StatusTone.warning, icon: Icons.warning_amber_rounded),
                            ],
                          ),
                        ),
                        if (i < c.scenarios.length - 1)
                          const Divider(height: 1, color: AppColors.divider),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const AlertBanner(
                  type: AlertType.info,
                  title: 'Edición en el cliente web',
                  message: 'Aquí puedes consultar la configuración vigente. Los cambios se hacen '
                      'desde el cliente web del sistema.',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
