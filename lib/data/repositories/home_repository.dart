import '../models/home_summary.dart';

/// Contrato para la pantalla de inicio (`GET /yo/inicio`). Implementación: `ApiHomeRepository`.
abstract class HomeRepository {
  Future<HomeSummary> getSummary(String userId);

  Future<DateTime> syncNow();
}
