import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/widgets/widgets.dart';
import '../../data/app_services.dart';
import '../../data/models/trap.dart';
import '../../shared/shared.dart';
import 'agronomist_controller.dart';

/// Trampas de un lote, para consultarlas durante la revisión.
class RecordTrapsScreen extends StatefulWidget {
  const RecordTrapsScreen({
    super.key,
    this.lotId,
    this.title = 'Revisión',
    this.showBack = true,
  });

  /// null = el lote que está consultando el agrónomo (pestaña «Trampas»).
  final String? lotId;

  /// 'Revisión' al llegar desde un registro; 'Trampas' como pestaña del rol.
  final String title;
  final bool showBack;

  @override
  State<RecordTrapsScreen> createState() => _RecordTrapsScreenState();
}

class _RecordTrapsScreenState extends State<RecordTrapsScreen> {
  late Future<List<Trap>> _future = _load();

  Future<List<Trap>> _load() async =>
      AppServices.lots.getTraps(widget.lotId ?? await AgronomistController.instance.ensureLot());

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: SimpleAppBar(title: widget.title, showBack: widget.showBack),
      body: FutureBuilder<List<Trap>>(
        future: _future,
        builder: (context, snap) => AsyncBody<List<Trap>>(
          snapshot: snap,
          what: 'las trampas',
          onRetry: _reload,
          isEmpty: (t) => t.isEmpty,
          empty: const EmptyState(
            icon: Icons.science_outlined,
            title: 'Sin trampas',
            message: 'Este lote no tiene trampas registradas.',
          ),
          builder: (trampas) => ResponsiveBody(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screenH),
              children: [
                const SectionTitle('Trampas por lote'),
                const SizedBox(height: AppSpacing.md),
                for (final t in trampas) ...[
                  MenuTile(
                    icon: Icons.lightbulb_outline,
                    title: t.label,
                    subtitle: t.lastReadingDate == null
                        ? 'Sin lecturas'
                        : 'Última lectura ${Fmt.date(t.lastReadingDate!)}',
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.agroRecordReading, arguments: t.id),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
