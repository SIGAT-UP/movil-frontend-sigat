import 'package:flutter/material.dart';

import '../../app/shell_nav.dart';
import '../../core/widgets/widgets.dart';
import '../../data/app_services.dart';
import '../../data/models/visit.dart';
import '../../shared/shared.dart';
import '../sync/sync_controller.dart';

/// P07-P — Sincronización del productor. Usa el mismo [SyncController] que el técnico.
/// Estados: P07 pendientes · P07b sincronizando · P07c todo sincronizado · P07d error.
class ProducerSyncScreen extends StatefulWidget {
  const ProducerSyncScreen({super.key});

  @override
  State<ProducerSyncScreen> createState() => _ProducerSyncScreenState();
}

class _ProducerSyncScreenState extends State<ProducerSyncScreen> {
  final _sync = SyncController.instance;

  @override
  void initState() {
    super.initState();
    // Se carga después del primer frame: avisar a otros widgets durante el build no está permitido.
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync.load());
  }

  RecordStatus _statusOf(int i, SyncItem item) {
    if (item.synced) return _sync.phase == SyncPhase.done ? RecordStatus.confirmado : RecordStatus.enviado;
    if (_sync.phase == SyncPhase.syncing) {
      return _sync.currentIndex == i ? RecordStatus.enviando : RecordStatus.pendiente;
    }
    if (_sync.phase == SyncPhase.error) return RecordStatus.local;
    return RecordStatus.pendiente;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SimpleAppBar(title: 'Sincronización'),
      body: ListenableBuilder(
        listenable: Listenable.merge([_sync, AppServices.isOnline]),
        builder: (context, _) {
          if (_sync.loading) return const AppLoader();
          final online = AppServices.isOnline.value;
          return Column(
            children: [
              Expanded(
                child: ResponsiveBody(
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.screenH),
                    children: [
                      ..._header(online),
                      const SizedBox(height: AppSpacing.lg),
                      for (var i = 0; i < _sync.items.length; i++) ...[
                        SyncRecordTile(
                          title: _sync.items[i].label,
                          date: _sync.items[i].observedAt,
                          status: _statusOf(i, _sync.items[i]),
                        ),
                        const SizedBox(height: 10),
                      ],
                      ..._footer(),
                    ],
                  ),
                ),
              ),
              BottomActions(children: _actions(online)),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _header(bool online) {
    final total = _sync.items.length;
    switch (_sync.phase) {
      case SyncPhase.syncing:
        final sending = (_sync.currentIndex ?? _sync.syncedCount) + 1;
        return [
          const Align(
            alignment: Alignment.centerLeft,
            child: StatusBadge('Sincronizando...', tone: StatusTone.info, icon: Icons.sync),
          ),
          const SizedBox(height: AppSpacing.md),
          ProgressHeader(
            label: 'Enviando ${total == 0 ? 0 : sending.clamp(1, total)} de $total registros...',
            value: total == 0 ? 0 : _sync.syncedCount / total,
          ),
        ];
      case SyncPhase.done:
        return [
          const Align(alignment: Alignment.centerLeft, child: StatusBadge('Todo actualizado', icon: Icons.check)),
          const SizedBox(height: AppSpacing.xl),
          SuccessHero(
            title: total == 0 ? 'Todo está al día' : 'Registros sincronizados',
            message: total == 0
                ? 'No tienes autorreportes pendientes.'
                : 'Todos tus autorreportes han sido confirmados por el servidor.',
          ),
        ];
      case SyncPhase.error:
        return [
          const AlertBanner(
            title: 'No se pudo sincronizar',
            message: 'Verifica la conexión a Internet e intenta de nuevo. Tus datos no se han perdido.',
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('${_sync.pendingCount} registros sin sincronizar', style: AppText.h3),
        ];
      case SyncPhase.idle:
        return [
          Align(alignment: Alignment.centerLeft, child: ConnectionChip(isOnline: online)),
          const SizedBox(height: AppSpacing.md),
          Text('${_sync.pendingCount} registros pendientes', style: AppText.h3),
        ];
    }
  }

  List<Widget> _footer() {
    final last = _sync.lastSync;
    switch (_sync.phase) {
      case SyncPhase.syncing:
        return const [
          AlertBanner(type: AlertType.warning, title: 'No cierres la app durante la sincronización.'),
        ];
      case SyncPhase.done:
        return [
          if (last != null) Text('Sincronizado: ${Fmt.date(last)}, ${Fmt.time24(last)}', style: AppText.caption),
        ];
      case SyncPhase.error:
        return const [
          AlertBanner(type: AlertType.info, title: 'Los datos permanecen guardados en tu dispositivo.'),
        ];
      case SyncPhase.idle:
        return [
          if (last != null)
            Text('Última sincronización: ${Fmt.date(last)}, ${Fmt.time(last)}', style: AppText.caption),
          const SizedBox(height: AppSpacing.md),
          const AlertBanner(type: AlertType.info, title: 'Solo se sincronizan tus autorreportes.'),
        ];
    }
  }

  List<Widget> _actions(bool online) {
    void home() => ProducerNav.goTo(context, ProducerTab.inicio);
    switch (_sync.phase) {
      case SyncPhase.syncing:
        return const [PrimaryButton(label: 'Sincronizando...', isLoading: true, onPressed: null)];
      case SyncPhase.done:
        return [PrimaryButton(label: 'Volver al inicio', color: AppColors.primaryDark, onPressed: home)];
      case SyncPhase.error:
        return [
          PrimaryButton(label: 'Reintentar sincronización', color: AppColors.primaryDark, onPressed: _sync.syncAll),
          SecondaryButton(label: 'Volver al inicio', onPressed: home),
        ];
      case SyncPhase.idle:
        return [
          PrimaryButton(
            label: online ? 'Sincronizar ahora' : 'Sin conexión',
            icon: online ? Icons.sync : Icons.wifi_off,
            color: AppColors.primaryDark,
            onPressed: online ? _sync.syncAll : null,
          ),
        ];
    }
  }
}
