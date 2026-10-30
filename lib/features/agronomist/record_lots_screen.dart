import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/widgets/widgets.dart';
import '../../data/app_services.dart';
import '../../data/models/lot.dart';
import 'agronomist_controller.dart';
import '../../shared/shared.dart';

/// Lotes incluidos en la visita que se está revisando.
class RecordLotsScreen extends StatefulWidget {
  const RecordLotsScreen({super.key, required this.recordId});
  final String recordId;

  @override
  State<RecordLotsScreen> createState() => _RecordLotsScreenState();
}

class _RecordLotsScreenState extends State<RecordLotsScreen> {
  late Future<List<Lot>> _future = _load();

  /// Los errores (sin conexión, servidor no disponible) se muestran; no se ocultan lotes.
  Future<List<Lot>> _load() async {
    final record = AgronomistController.instance.recordById(widget.recordId) ??
        await AppServices.agronomist.getRecord(widget.recordId);
    return [for (final id in record.lotIds) await AppServices.lots.getLot(id)];
  }

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SimpleAppBar(title: 'Revisión'),
      body: FutureBuilder<List<Lot>>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) return ErrorState(error: snap.error, what: 'los lotes de la visita', onRetry: _reload);
          if (!snap.hasData) return const AppLoader();
          final lotes = snap.data!;
          if (lotes.isEmpty) {
            return const EmptyState(
              icon: Icons.layers_outlined,
              title: 'Sin lotes',
              message: 'Esta visita no tiene lotes asociados.',
            );
          }
          return ResponsiveBody(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screenH),
              children: [
                const SectionTitle('Lotes visitados por el técnico'),
                const SizedBox(height: AppSpacing.md),
                for (final l in lotes) ...[
                  MenuTile(
                    icon: Icons.eco_outlined,
                    title: l.name,
                    subtitle: '${l.trapCount} trampas · ${l.producer}',
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.agroRecordTraps, arguments: l.id),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
