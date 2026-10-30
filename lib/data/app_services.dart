import 'package:flutter/foundation.dart';

import '../app/routes.dart';
import 'api/api_client.dart';
import 'local/pending_store.dart';
import 'models/user_session.dart';
import 'repositories/agronomist_repository.dart';
import 'repositories/api_auth_repository.dart';
import 'repositories/api_repositories.dart';
import 'repositories/auth_repository.dart';
import 'repositories/field_repositories.dart';
import 'repositories/home_repository.dart';
import 'repositories/notifications_repository.dart';
import 'repositories/planning_repository.dart';
import 'repositories/producer_repository.dart';
import 'repositories/profile_repository.dart';

/// Punto ÚNICO donde se decide qué implementación usa la app.
///
/// Todo es real: cada repositorio llama a `sigat-durazno-api` (URL por entorno en
/// `lib/core/config/api_config.dart`). No hay datos simulados.
///
/// * Funcionan contra el backend y la BD: inicio de sesión, avisos, perfil e inicio.
/// * El resto llama a su ruta del contrato; mientras el backend responda 501, la pantalla
///   dice «…todavía no está disponible en el servidor» (ver `api_repositories.dart`).
/// * Lo que se captura en campo se guarda en el TELÉFONO ([pending]) y se muestra como
///   «pendiente de enviar» hasta que el servidor confirme que lo recibió.
class AppServices {
  AppServices._();

  /// Cliente HTTP compartido (tokens en almacenamiento seguro, renovación automática).
  static ApiClient api = ApiClient();

  /// Registros capturados en el teléfono y aún no confirmados por el servidor.
  static PendingStore pending = SharedPrefsPendingStore();

  // Se crean al primer uso con [api] y [pending]; [connect] los vuelve a armar.
  static AuthRepository auth = ApiAuthRepository(client: api);
  static HomeRepository home = ApiHomeRepository(api, pending);
  static LotsRepository lots = ApiLotsRepository(api);
  static TrapsRepository traps = ApiTrapsRepository(api);
  static ReadingsRepository readings = ApiReadingsRepository(pending);
  static MapRepository maps = ApiMapRepository(api);
  static SyncRepository sync = ApiSyncRepository(pending);
  static HistoryRepository history = ApiHistoryRepository(api, pending);
  static ProducerRepository producer = ApiProducerRepository(api, pending);
  static ProfileRepository profile = ApiProfileRepository(api);
  static NotificationsRepository notifications = ApiNotificationsRepository(api, routeFor: rutaDeAviso);
  static PlanningRepository plannings = ApiPlanningRepository(api, pending);
  static AgronomistRepository agronomist = ApiAgronomistRepository(api);

  /// Vuelve a armar todos los repositorios sobre otro cliente y otra cola local.
  /// Lo usan las pruebas, con un backend de prueba sin red.
  static void connect({ApiClient? client, PendingStore? store}) {
    api = client ?? api;
    pending = store ?? pending;
    auth = ApiAuthRepository(client: api);
    home = ApiHomeRepository(api, pending);
    lots = ApiLotsRepository(api);
    traps = ApiTrapsRepository(api);
    readings = ApiReadingsRepository(pending);
    maps = ApiMapRepository(api);
    sync = ApiSyncRepository(pending);
    history = ApiHistoryRepository(api, pending);
    producer = ApiProducerRepository(api, pending);
    profile = ApiProfileRepository(api);
    notifications = ApiNotificationsRepository(api, routeFor: rutaDeAviso);
    plannings = ApiPlanningRepository(api, pending);
    agronomist = ApiAgronomistRepository(api);
  }

  /// Sesión actual, observable desde cualquier pantalla.
  static final session = ValueNotifier<UserSession?>(null);

  /// Estado REAL de conectividad. Lo actualiza [ConnectivityService] (connectivity_plus).
  /// Las pantallas solo lo escuchan; nunca lo cambian.
  static final isOnline = ValueNotifier<bool>(true);
}

/// `destino.ruta` de un aviso del backend → pantalla de la app. Los avisos con un destino
/// que la app no tiene (p. ej. `/admin/usuarios`, que es de la web) se muestran sin abrir nada.
String? rutaDeAviso(String ruta) {
  if (ruta.startsWith('/planificaciones')) return AppRoutes.planningDetail;
  if (ruta.startsWith('/revisiones')) return AppRoutes.agroRecordReview;
  if (ruta.startsWith('/lotes')) return AppRoutes.lotDetail;
  if (ruta.startsWith('/sincronizacion')) return AppRoutes.sync;
  return null;
}
