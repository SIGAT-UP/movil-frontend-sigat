import 'package:flutter/material.dart';

import '../../app/shell_nav.dart';
import '../../core/widgets/widgets.dart';
import '../../data/app_services.dart';
import 'sync_controller.dart';

/// M09-T — Sincronización: pendiente → sincronizando → todo actualizado.
class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final _sync = SyncController.instance;

  @override
  void initState() {
    super.initState();
    // Se carga después del primer frame: avisar a otros widgets durante el build no está permitido.
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync.load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SimpleAppBar(title: 'Sincronización'),
      body: ListenableBuilder(
        listenable: Listenable.merge([_sync, AppServices.isOnline]),
        builder: (context, _) {
          if (_sync.loading) return const AppLoader();
          final online = AppServices.isOnline.value;
          final total = _sync.items.length;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.screenH),
                  children: [
                    ..._header(online, total),
                    const SizedBox(height: AppSpacing.lg),
                    for (final item in _sync.items) ...[
                      ChecklistTile(
                        title: item.label,
                        subtitle: item.synced
                            ? 'Sincronizado'
                            : 'Pendiente · observación ${Fmt.dayMonth(item.observedAt)}, ${Fmt.time24(item.observedAt)}',
                        done: item.synced,
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (_sync.error != null) ...[
                      const SizedBox(height: 4),
                      AlertBanner(type: AlertType.warning, title: 'No se completó', message: _sync.error),
                      const SizedBox(height: 10),
                    ],
                    if (_sync.isSyncing)
                      const Text('Puedes seguir usando la aplicación mientras se sincroniza.',
                          style: AppText.caption),
                    if (_sync.lastSync != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Última sincronización: ${Fmt.date(_sync.lastSync!)}, ${Fmt.time(_sync.lastSync!)}',
                          style: AppText.caption,
                        ),
                      ),
                  ],
                ),
              ),
              BottomActions(children: [
                if (_sync.phase == SyncPhase.done)
                  SecondaryButton(label: 'Ir al inicio', onPressed: () => ShellNav.goTo(context, AppTab.inicio))
                else
                  PrimaryButton(
                    label: _sync.phase == SyncPhase.error ? 'Reintentar' : 'Sincronizar',
                    loadingLabel: 'Sincronizando...',
                    isLoading: _sync.isSyncing,
                    color: AppColors.primaryDark,
                    onPressed: online ? _sync.syncAll : null,
                  ),
              ]),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _header(bool online, int total) {
    switch (_sync.phase) {
      case SyncPhase.syncing:
        return [
          const Align(
            alignment: Alignment.centerLeft,
            child: StatusBadge('Sincronizando...', tone: StatusTone.info, icon: Icons.sync),
          ),
          const SizedBox(height: 12),
          ProgressHeader(
            label: 'Sincronizando ${_sync.syncedCount} de $total...',
            value: total == 0 ? 0 : _sync.syncedCount / total,
          ),
        ];
      case SyncPhase.done:
        return const [
          Text('Todo está actualizado', style: AppText.h1),
          SizedBox(height: 6),
          Align(alignment: Alignment.centerLeft, child: StatusBadge('Todo actualizado', icon: Icons.check)),
        ];
      case SyncPhase.idle:
      case SyncPhase.error:
        return [
          Text('${_sync.pendingCount} registros pendientes',
              style: AppText.h1),
          const SizedBox(height: 6),
          Align(alignment: Alignment.centerLeft, child: ConnectionChip(isOnline: online)),
          if (!online) ...[
            const SizedBox(height: 12),
            const AlertBanner(
              type: AlertType.info,
              title: 'Sin conexión',
              message: 'Los registros siguen guardados en el dispositivo. Sincroniza cuando tengas internet.',
            ),
          ],
        ];
    }
  }
}
