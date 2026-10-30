import 'package:flutter/foundation.dart';

import '../../data/app_services.dart';
import '../../data/models/producer.dart';

/// Estado compartido de las pantallas del productor (Inicio, Mi cultivo, Historial).
/// Tras guardar una aplicación o una cosecha se recarga solo.
class ProducerController extends ChangeNotifier {
  ProducerController._();
  static final instance = ProducerController._();

  CropSummary? summary;
  List<ActivityRecord> activity = [];
  bool loading = false;
  String? error;

  String get _userId => AppServices.session.value?.userId ?? '';

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    // Por separado: si el servidor aún no da el resumen, los autorreportes guardados en el
    // teléfono (pendientes de enviar) se siguen viendo en el historial.
    try {
      summary = await AppServices.producer.getCropSummary(_userId);
    } catch (e) {
      error = e.toString();
    }
    try {
      activity = await AppServices.producer.getActivity(_userId);
    } catch (e) {
      error ??= e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> saveApplication(PhytoApplication a) async {
    await AppServices.producer.saveApplication(a);
    await load();
  }

  Future<void> saveHarvest(HarvestReport h) async {
    await AppServices.producer.saveHarvest(h);
    await load();
  }

  void reset() {
    summary = null;
    activity = [];
    loading = false;
    error = null;
    notifyListeners();
  }
}
