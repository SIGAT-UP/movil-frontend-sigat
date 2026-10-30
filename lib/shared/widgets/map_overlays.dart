import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';
import '../../data/models/lot.dart';
import '../../data/models/trap.dart';
import 'mtd_indicator.dart';

/// FONDO PROVISIONAL DEL MAPA.
/// Cuando integres MapLibre, reemplaza este widget por el `MapLibreMap`
/// y deja todo lo demás (barra, leyenda, botones, hojas) igual encima.
class MapPlaceholder extends StatelessWidget {
  const MapPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPainter(),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 40, color: AppColors.mapLabel),
            SizedBox(height: 6),
            Text('Aquí va el mapa (MapLibre)', style: AppText.secondary),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.mapPlaceholder);
    final p = Paint()
      ..color = AppColors.mapGrid
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Contenedor blanco flotante con sombra (base de los overlays del mapa).
class MapFloatingCard extends StatelessWidget {
  const MapFloatingCard({super.key, required this.child, this.padding = const EdgeInsets.all(10), this.radius = 12});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: AppShadows.floating,
        ),
        child: child,
      );
}

/// Barra superior: "← Mapa del predio / Finca El Mirador    [≡ Lista]".
class MapTopBar extends StatelessWidget {
  const MapTopBar({super.key, required this.title, this.subtitle, this.onBack, this.onList});
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final VoidCallback? onList;

  @override
  Widget build(BuildContext context) {
    return MapFloatingCard(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              tooltip: 'Atrás',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.arrow_back, size: 20),
              onPressed: onBack,
            )
          else
            const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.title),
                if (subtitle != null)
                  Text(subtitle!, style: AppText.caption),
              ],
            ),
          ),
          if (onList != null)
            TextButton.icon(
              onPressed: onList,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: AppColors.primaryDark,
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(Icons.list, size: 16),
              label: const Text('Lista', style: AppText.bodySmStrong),
            ),
        ],
      ),
    );
  }
}

class LegendItem {
  const LegendItem(this.label, this.color);
  final String label;
  final Color color;
}

/// Leyenda de colores de las trampas.
class MapLegend extends StatelessWidget {
  const MapLegend({super.key, this.items = defaultItems});

  static const defaultItems = [
    LegendItem('Normal', AppColors.primary),
    LegendItem('Pendiente', AppColors.warningStrong),
    LegendItem('Atención', AppColors.error),
    LegendItem('Técnico', AppColors.info),
  ];

  final List<LegendItem> items;

  @override
  Widget build(BuildContext context) {
    return MapFloatingCard(
      radius: 100,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Wrap(
        spacing: 10,
        runSpacing: 4,
        children: [
          for (final i in items)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: i.color, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text(i.label, style: AppText.micro.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ],
            ),
        ],
      ),
    );
  }
}

/// Botones redondos de la derecha: +, −, capas, mi ubicación.
class MapControls extends StatelessWidget {
  const MapControls({super.key, this.onZoomIn, this.onZoomOut, this.onLayers, this.onLocate});
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final VoidCallback? onLayers;
  final VoidCallback? onLocate;

  Widget _btn(IconData icon, String tip, VoidCallback? onTap, {Color? color}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AppIconButton(
          icon: icon,
          tooltip: tip,
          onPressed: onTap,
          variant: AppIconButtonVariant.floating,
          color: color,
        ),
      );

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(Icons.add, 'Acercar', onZoomIn),
          _btn(Icons.remove, 'Alejar', onZoomOut),
          _btn(Icons.layers_outlined, 'Capas', onLayers),
          _btn(Icons.my_location, 'Mi ubicación', onLocate, color: AppColors.info),
        ],
      );
}

/// Botones inferiores: "Escanear trampa" y "# Ingresar código ICA".
class MapActionBar extends StatelessWidget {
  const MapActionBar({super.key, required this.onScan, required this.onEnterCode});
  final VoidCallback onScan;
  final VoidCallback onEnterCode;

  Widget _pill(IconData icon, String label, VoidCallback onTap) => Expanded(
        child: SizedBox(
          height: 46,
          child: FilledButton.icon(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              shape: const StadiumBorder(),
              elevation: 3,
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            icon: Icon(icon, size: 18),
            label: FittedBox(
              child: Text(label, style: AppText.label),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Row(
        children: [
          _pill(Icons.qr_code_scanner, 'Escanear trampa', onScan),
          const SizedBox(width: 10),
          _pill(Icons.tag, 'Ingresar código ICA', onEnterCode),
        ],
      );
}

/// Aviso "Sin conexión — trabajando localmente".
class MapOfflineBanner extends StatelessWidget {
  const MapOfflineBanner({super.key});

  @override
  Widget build(BuildContext context) => const AlertBanner(
        type: AlertType.info,
        title: 'Sin conexión — trabajando localmente',
        message: 'Mapa y trampas descargados disponibles.',
      );
}

/// S04d — "Mapa satelital no descargado".
class MapDownloadCard extends StatelessWidget {
  const MapDownloadCard({
    super.key,
    required this.onDownload,
    required this.downloading,
    required this.progress,
    this.error,
  });

  final VoidCallback onDownload;
  final bool downloading;
  final double progress;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return MapFloatingCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SoftIconCircle(icon: Icons.download_outlined),
          const SizedBox(height: 12),
          const Text('Mapa satelital no descargado',
              textAlign: TextAlign.center, style: AppText.h3),
          const SizedBox(height: 6),
          const Text(
            'Los límites de lotes y trampas siguen disponibles. Descargue el mapa con conexión antes de la próxima visita.',
            textAlign: TextAlign.center,
            style: AppText.caption,
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            AlertBanner(title: 'No se pudo descargar', message: error),
          ],
          const SizedBox(height: 16),
          if (downloading) ...[
            ProgressHeader(label: 'Descargando mapa...', trailing: '${(progress * 100).round()} %', value: progress),
          ] else
            SecondaryButton(label: 'Descargar Mapa', onPressed: onDownload),
        ],
      ),
    );
  }
}

/// S04a — Hoja inferior al tocar un lote en el mapa.
class LotMapSheet extends StatelessWidget {
  const LotMapSheet({super.key, required this.lot, required this.onViewDetail, this.onClose});
  final Lot lot;
  final VoidCallback onViewDetail;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final mtd = lot.control?.mtd;
    return MapFloatingCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(lot.name, style: AppText.h3)),
            if (onClose != null) IconButton(onPressed: onClose, icon: const Icon(Icons.close, size: 18)),
          ]),
          Text('${lot.trapCount} trampas · ${lot.control?.exportThreshold ?? ''}',
              style: AppText.caption),
          const SizedBox(height: 8),
          MtdIndicator(value: mtd, thresholdLabel: lot.control?.exportThreshold),
          const SizedBox(height: 12),
          PrimaryButton(label: 'Ver detalle del lote', onPressed: onViewDetail),
        ],
      ),
    );
  }
}

/// S04b — Hoja inferior al tocar una trampa en el mapa.
class TrapMapSheet extends StatelessWidget {
  const TrapMapSheet({
    super.key,
    required this.trap,
    required this.lotName,
    required this.onViewTrap,
    this.onClose,
    this.actionLabel = 'Ver trampa',
    this.headline,
  });
  final Trap trap;
  final String lotName;
  final VoidCallback onViewTrap;
  final VoidCallback? onClose;
  final String actionLabel;

  /// Texto pequeño arriba (ej. "Siguiente trampa del recorrido").
  final String? headline;

  @override
  Widget build(BuildContext context) {
    return MapFloatingCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (headline != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: StatusBadge(headline!, tone: StatusTone.warning, icon: Icons.directions_walk),
            ),
          Row(children: [
            Expanded(
              child: Text('${trap.label} · ${trap.type}',
                  style: AppText.h3),
            ),
            if (onClose != null) IconButton(onPressed: onClose, icon: const Icon(Icons.close, size: 18)),
          ]),
          Text(
            '$lotName · Última lectura ${trap.lastReadingDate == null ? '-' : Fmt.date(trap.lastReadingDate!)}',
            style: AppText.caption,
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${trap.lastCaptures ?? 0} adultos',
                        style: AppText.display),
                    const Text('última captura', style: AppText.micro),
                  ],
                ),
              ),
              StatusBadge(trap.active ? 'Activa' : 'Inactiva',
                  tone: trap.active ? StatusTone.success : StatusTone.neutral, icon: Icons.check),
            ],
          ),
          const SizedBox(height: 12),
          PrimaryButton(label: actionLabel, onPressed: onViewTrap),
        ],
      ),
    );
  }
}
