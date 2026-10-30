import '../models/producer.dart';

/// Contrato de datos del PRODUCTOR. La UI solo conoce esta interfaz.
/// Implementación real sugerida: guardar en la base local (drift) + encolar
/// en la sincronización, igual que las lecturas del técnico.
abstract class ProducerRepository {
  Future<CropSummary> getCropSummary(String userId);

  /// Guarda el autorreporte en el dispositivo y lo deja pendiente de sincronizar.
  Future<void> saveApplication(PhytoApplication application);

  /// Guarda el autorreporte en el dispositivo y lo deja pendiente de sincronizar.
  Future<void> saveHarvest(HarvestReport harvest);

  /// Historial: visitas de vigilancia + aplicaciones + cosechas, del más reciente al más antiguo.
  Future<List<ActivityRecord>> getActivity(String userId);
}
