import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../app/shell_nav.dart';
import '../../core/widgets/widgets.dart';
import '../../data/app_services.dart';
import '../../data/models/trap.dart';
import '../traps/trap_flow.dart';
import '../visit/visit_controller.dart';
import '../../shared/shared.dart';

/// S04 — Mapa del predio (pestaña "Mapa").
/// El fondo es provisional (`MapPlaceholder`); todo lo demás ya funciona.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _visit = VisitController.instance;

  String? _checkedPredio;
  bool? _downloaded; // null = verificando
  bool _downloading = false;
  double _progress = 0;
  String? _downloadError;

  @override
  void initState() {
    super.initState();
    _visit.addListener(_onVisitChanged);
    _onVisitChanged();
  }

  @override
  void dispose() {
    _visit.removeListener(_onVisitChanged);
    super.dispose();
  }

  /// Cada vez que cambia el lote activo, se verifica si su mapa está descargado.
  Future<void> _onVisitChanged() async {
    final predio = _visit.activeLot?.predioId;
    if (predio == null || predio == _checkedPredio) {
      if (mounted) setState(() {});
      return;
    }
    _checkedPredio = predio;
    setState(() => _downloaded = null);
    final ok = await AppServices.maps.isMapDownloaded(predio);
    if (mounted && _checkedPredio == predio) setState(() => _downloaded = ok);
  }

  Future<void> _download() async {
    final predio = _visit.activeLot?.predioId;
    if (predio == null) return;
    setState(() {
      _downloading = true;
      _progress = 0;
      _downloadError = null;
    });
    try {
      await AppServices.maps.downloadMap(predio, onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      });
      if (mounted) setState(() => _downloaded = true);
    } catch (e) {
      if (mounted) setState(() => _downloadError = e.toString());
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lot = _visit.activeLot;
    final focused = _visit.focusedTrap;

    return Stack(
      fit: StackFit.expand,
      children: [
        const MapPlaceholder(),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MapTopBar(
                  title: 'Mapa del predio',
                  subtitle: lot == null ? 'Sin lote activo' : '${lot.predioName} · ${lot.name}',
                  onBack: () => ShellNav.tab.value = AppTab.inicio,
                  onList: lot == null ? null : () => ShellNav.tab.value = AppTab.trampas,
                ),
                const SizedBox(height: 8),
                const Center(child: MapLegend()),
                ValueListenableBuilder<bool>(
                  valueListenable: AppServices.isOnline,
                  builder: (_, online, __) => online
                      ? const SizedBox.shrink()
                      : const Padding(padding: EdgeInsets.only(top: 8), child: MapOfflineBanner()),
                ),
                Expanded(child: _middle(lot != null)),
                if (lot != null && _downloaded == true) ...[
                  if (focused != null) ...[
                    TrapMapSheet(
                      trap: focused,
                      lotName: lot.name,
                      headline: _visit.nextTrap?.id == focused.id ? 'Siguiente trampa del recorrido' : null,
                      onClose: () => _visit.focusTrap(null),
                      // Al llegar a la trampa se escanea (o se usa "Ingresar código ICA").
                      actionLabel: _visit.stateOf(focused) == TrapVisitState.pendiente
                          ? 'Llegué · Escanear trampa'
                          : 'Ver trampa',
                      onViewTrap: () => _visit.stateOf(focused) == TrapVisitState.pendiente
                          ? Navigator.of(context).pushNamed(AppRoutes.scanTrap)
                          : _openTrap(focused),
                    ),
                    const SizedBox(height: 10),
                  ],
                  MapActionBar(
                    onScan: () => Navigator.of(context).pushNamed(AppRoutes.scanTrap),
                    onEnterCode: () => Navigator.of(context).pushNamed(AppRoutes.identifyTrap),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _middle(bool hasLot) {
    if (!hasLot) {
      return Center(
        child: MapFloatingCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SoftIconCircle(icon: Icons.location_on_outlined),
              const SizedBox(height: 10),
              const Text('Sin inspección activa', style: AppText.h3),
              const SizedBox(height: 4),
              const Text('Selecciona un lote asignado e inicia la inspección.',
                  textAlign: TextAlign.center, style: AppText.secondary),
              const SizedBox(height: 14),
              SecondaryButton(
                label: 'Ver lotes asignados',
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.lots),
              ),
            ],
          ),
        ),
      );
    }
    if (_downloaded == null) {
      return const AppLoader();
    }
    if (_downloaded == false) {
      return Center(
        child: SingleChildScrollView(
          child: MapDownloadCard(
            onDownload: _download,
            downloading: _downloading,
            progress: _progress,
            error: _downloadError,
          ),
        ),
      );
    }
    return Align(
      alignment: Alignment.centerRight,
      child: MapControls(
        // Conectar al controlador de MapLibre cuando se integre.
        onZoomIn: () {},
        onZoomOut: () {},
        onLayers: () {},
        onLocate: () {},
      ),
    );
  }

  Future<void> _openTrap(Trap trap) async {
    final lookup = await AppServices.traps.findByCode(trap.icaCode, activeLotId: _visit.activeLot?.id);
    if (!mounted || lookup == null) return;
    openTrapIdentified(context, lookup);
  }
}
