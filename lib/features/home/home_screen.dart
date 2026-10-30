import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/widgets/widgets.dart';
import '../../data/app_services.dart';
import '../../data/models/home_summary.dart';
import '../../data/repositories/field_repositories.dart';
import '../auth/logout.dart';
import '../lots/lots_screen.dart';
import '../notifications/notifications_screen.dart';
import '../planning/planning_inbox_card.dart';
import '../sync/sync_controller.dart';
import '../visit/visit_controller.dart';

/// M01-T — Inicio técnico.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onOpenLots, this.onOpenSync});

  /// Callbacks para que el shell decida a dónde navegar.
  final VoidCallback? onOpenLots;
  final VoidCallback? onOpenSync;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<HomeSummary> _future;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
    // Al finalizar lotes o sincronizar, los indicadores se actualizan solos.
    VisitController.instance.addListener(_onDataChanged);
    SyncController.instance.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    VisitController.instance.removeListener(_onDataChanged);
    SyncController.instance.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (!mounted) return;
    setState(() {
      _future = _load();
     });
  }

  Future<HomeSummary> _load() =>
      AppServices.home.getSummary(AppServices.session.value?.userId ?? '');

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() {
      _future = _load();
    });
    await _future;
    
  }

  Future<void> _sync() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    try {
      await AppServices.home.syncNow();
      await _refresh();
    } on DataException catch (e) {
      // Sin conexión o servidor aún sin sincronización: lo registrado sigue en el teléfono.
      if (mounted) AppMessenger.pending('No se envió nada', message: e.message);
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = AppServices.session.value;
    final roleShort = session?.role.label == 'Técnico' ? 'Téc. ' : '';

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        child: FutureBuilder<HomeSummary>(
          future: _future,
          builder: (context, snap) {
            return ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              children: [
                // Saludo + estado de conexión
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenH,
                    AppSpacing.xl,
                    AppSpacing.screenH,
                    0,
                  ),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: AppServices.isOnline,
                    builder: (_, online, __) => GreetingHeader(
                      title: 'Hola, $roleShort${session?.shortName ?? ''}',
                      subtitle: 'Bienvenido al sistema',
                      titleStyle: AppText.h2,
                      isOnline: online,
                      // Igual que en los demás roles: campana y cerrar sesión arriba.
                      actions: [
                        const NotificationBell(),
                        AppIconButton(
                          icon: Icons.logout,
                          tooltip: 'Cerrar sesión',
                          onPressed: () => confirmAndLogout(context),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Banner sin texto
                const SizedBox(
                  height: 120,
                  child: AssetOrFallback(
                    'assets/images/home_banner.jpg',
                    fallbackIcon: Icons.agriculture,
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenH,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.xl),
                      NavActionCard(
                        icon: Icons.location_on,
                        title: 'Mis Lotes Asignados',
                        subtitle:
                            'Consulte y gestione los lotes asignados a su usuario',
                        onTap: widget.onOpenLots ??
                            () => Navigator.of(context)
                                .pushNamed(AppRoutes.lots),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const PlanningInboxCard(
                        subtitle: 'Lotes y fechas que te asignó el agrónomo',
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        children: [
                          const Text('Tu jornada', style: AppText.h3),
                          const Spacer(),
                          const Icon(
                            Icons.calendar_month_outlined,
                            size: 18,
                            color: AppColors.primaryDark,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(snap.data?.date ?? DateTime.now()),
                            style: AppText.caption,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (snap.hasError)
                        AlertBanner(
                          title: 'No se pudo cargar tu jornada',
                          message: '${snap.error is DataException ? (snap.error as DataException).message : 'Error inesperado.'} '
                              'Desliza hacia abajo para reintentar.',
                        )
                      else if (!snap.hasData)
                        const AppLoader(
                          padding: EdgeInsets.all(AppSpacing.xl),
                        )
                      else ...[
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: StatCard(
                                  // «—» = el servidor aún no envía este dato (nunca un número inventado).
                                  value: '${snap.data!.assignedLots ?? '—'}',
                                  label: 'Mis lotes asignados',
                                  imagePath: 'assets/images/stat_lotes.png',
                                  fallbackIcon: Icons.park_outlined,
                                  onTap: widget.onOpenLots,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: StatCard(
                                  value: '${snap.data!.pendingVisits ?? '—'}',
                                  label: 'Pendiente de visita',
                                  caption: snap.data!.nextVisitTime,
                                  // Abre los lotes asignados filtrados en «Pendientes».
                                  onTap: () => Navigator.of(context)
                                      .pushNamed(AppRoutes.lots, arguments: LotsFilter.pendientes),
                                  imagePath:
                                      'assets/images/stat_pendientes.png',
                                  fallbackIcon: Icons.fact_check_outlined,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Center(
                          child: SyncStatusCard(
                            title: _syncing
                                ? 'Sincronizando...'
                                : 'Última sincronización',
                            subtitle: [
                              snap.data!.lastSync == null
                                  ? 'Ninguna confirmada por el servidor'
                                  : '${_formatDate(snap.data!.lastSync!)} · ${_formatTime(snap.data!.lastSync!)}',
                              if (snap.data!.pendingLocal > 0)
                                '${snap.data!.pendingLocal} pendiente${snap.data!.pendingLocal == 1 ? '' : 's'} en este teléfono',
                            ].join(' · '),
                            onTap: widget.onOpenSync ?? _sync,
                            trailing: _syncing
                                ? const AppInlineLoader(
                                    size: 14,
                                    color: AppColors.primary,
                                  )
                                : ValueListenableBuilder<bool>(
                                    valueListenable: AppServices.isOnline,
                                    builder: (_, online, __) =>
                                        ConnectionChip(
                                      isOnline: online,
                                      onlineLabel: 'En línea',
                                      dense: true,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

const _months = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic'
];

String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1]} ${d.year}';

String _formatTime(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  return '$h:$m ${d.hour < 12 ? 'a.m.' : 'p.m.'}';
}