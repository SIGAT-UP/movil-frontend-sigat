import 'package:flutter/material.dart';

import '../data/app_services.dart';
import '../data/models/photo_file.dart';
import '../data/models/producer.dart';
import '../data/models/trap.dart';
import '../data/models/user_session.dart';
import '../data/models/planning.dart';
import '../features/agronomist/agronomist_shell.dart';
import '../features/agronomist/configuration_screen.dart';
import '../features/agronomist/created_planning_detail_screen.dart';
import '../features/agronomist/lot_info_screen.dart';
import '../features/agronomist/lot_summary_screen.dart';
import '../features/agronomist/my_plannings_screen.dart';
import '../features/agronomist/new_planning_wizard_screen.dart';
import '../features/agronomist/planning_hub_screen.dart';
import '../features/agronomist/record_lots_screen.dart';
import '../features/agronomist/record_reading_screen.dart';
import '../features/agronomist/record_review_screen.dart';
import '../features/agronomist/record_traps_screen.dart';
import '../features/agronomist/records_screen.dart';
import '../features/auth/access_context_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/recover_password_screen.dart';
import '../features/history/history_screen.dart';
import '../features/lots/lot_detail_screen.dart';
import '../features/lots/lots_screen.dart';
import '../features/producer/harvest_saved_screen.dart';
import '../features/producer/producer_shell.dart';
import '../features/producer/producer_sync_screen.dart';
import '../features/producer/register_application_screen.dart';
import '../features/producer/register_harvest_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/profile/notification_settings_screen.dart';
import '../features/profile/profile_photo_screen.dart';
import '../features/reading/evidence_screen.dart';
import '../features/reading/register_reading_screen.dart';
import '../features/shell/main_shell.dart';
import '../features/splash/splash_screen.dart';
import '../features/sync/sync_screen.dart';
import '../features/traps/identify_trap_screen.dart';
import '../features/traps/scan_trap_screen.dart';
import '../features/traps/trap_identified_screen.dart';
import '../features/planning/document_viewer_screen.dart';
import '../features/planning/planning_detail_screen.dart';
import '../features/planning/planning_list_screen.dart';
import '../features/planning/reject_planning_screen.dart';
import '../features/visit/finish_lot_screen.dart';
import '../features/visit/finish_visit_screen.dart';

/// Rutas con nombre (sirven igual para la versión web).
/// Para agregar una pantalla: constante + caso en [onGenerateRoute] + rol en [_roleOf].
class AppRoutes {
  AppRoutes._();

  // ---------- Acceso (todos los roles) ----------
  /// Bienvenida animada: solo al abrir la app. Pública.
  static const splash = '/splash';
  static const login = '/login';
  static const recover = '/recover';
  static const accessContext = '/access-context';

  // ---------- Técnico ----------
  static const home = '/home';
  static const lots = '/lots'; // arguments: LotsFilter? (filtro inicial)
  static const lotDetail = '/lots/detail'; // arguments: String lotId
  static const identifyTrap = '/trap/identify'; // arguments: String? código inicial
  static const scanTrap = '/trap/scan';
  static const trapIdentified = '/trap/identified'; // arguments: TrapLookup
  static const registerReading = '/reading'; // arguments: Trap
  static const evidence = '/reading/evidence'; // arguments: PhotoFile → devuelve EvidenceResult
  static const finishLot = '/visit/finish-lot';
  static const finishVisit = '/visit/finish';
  static const sync = '/sync';
  static const history = '/history';
  static const profilePhoto = '/profile/photo'; // arguments: PhotoFile → devuelve ProfilePhotoResult
  static const profileNotifications = '/profile/notifications';
  static const notifications = '/notifications';

  // ---------- Productor ----------
  static const producerHome = '/producer';
  static const producerApplication = '/producer/application';
  static const producerHarvest = '/producer/harvest';
  static const producerHarvestDone = '/producer/harvest/done'; // arguments: HarvestReport
  static const producerSync = '/producer/sync';

  // ---------- Planificaciones (las recibe el técnico o el productor) ----------
  static const planningList = '/plannings';
  static const planningDetail = '/plannings/detail'; // arguments: String planningId
  static const planningReject = '/plannings/reject'; // arguments: String planningId
  static const documentViewer = '/plannings/document'; // arguments: Planning

  // ---------- Agrónomo ----------
  static const agronomistHome = '/agronomist';
  static const agroRecords = '/agronomist/records';
  static const agroRecordReview = '/agronomist/records/review'; // arguments: String recordId
  static const agroRecordLots = '/agronomist/records/lots'; // arguments: String recordId
  static const agroRecordTraps = '/agronomist/records/traps'; // arguments: String lotId
  static const agroRecordReading = '/agronomist/records/reading'; // arguments: String trapId
  static const agroLotInfo = '/agronomist/lot';
  static const agroLotSummary = '/agronomist/lot/summary';
  static const agroConfig = '/agronomist/config';
  static const agroPlanningHub = '/agronomist/planning';
  static const agroPlanningTarget = '/agronomist/planning/target'; // arguments: PlanningTarget
  /// arguments: PlanningTarget (nueva desde cero) o Planning (nueva a partir de una rechazada)
  static const agroNewPlanning = '/agronomist/planning/new';
  static const agroMyPlannings = '/agronomist/planning/mine'; // arguments: PlanningTarget? (filtro)
  static const agroPlanningDetail = '/agronomist/planning/detail'; // arguments: String planningId

  /// Inicio de cada rol. null = el rol aún no tiene vistas en esta app.
  static String? homeFor(UserRole role) => switch (role) {
        UserRole.tecnico => home,
        UserRole.productor => producerHome,
        UserRole.agronomo => agronomistHome,
        _ => null,
      };

  /// ¿Puede este rol abrir esta ruta? Lo usan los avisos antes de navegar.
  static bool canAccess(String route, UserRole? role) {
    final owner = _roleOf(route);
    if (owner != null) return owner == role;
    if (_sharedRoutes.contains(route)) return _isKnown(role);
    return true;
  }

  /// Rol dueño de cada ruta (null = pública o compartida).
  static UserRole? _roleOf(String? name) {
    if (name == null) return null;
    if (name.startsWith('/agronomist')) return UserRole.agronomo;
    if (name.startsWith('/producer')) return UserRole.productor;
    if (_tecnicoRoutes.contains(name)) return UserRole.tecnico;
    return null;
  }

  static const _tecnicoRoutes = {
    home, lots, lotDetail, identifyTrap, scanTrap, trapIdentified, registerReading,
    evidence, finishLot, finishVisit, sync, history,
  };

  /// Rutas de más de un rol: hay que tener sesión con un rol conocido.
  /// Cada pantalla filtra además por el usuario de la sesión.
  static const _sharedRoutes = {
    planningList, planningDetail, planningReject, documentViewer,
    // Perfil: foto y preferencias de avisos son de todos los roles.
    profilePhoto, profileNotifications,
  };

  static bool _isKnown(UserRole? role) =>
      role != null && role != UserRole.desconocido;

  static Route<dynamic>? onGenerateRoute(RouteSettings s) {
    // Protección por rol: sin sesión o con otro rol, se vuelve al login.
    final role = AppServices.session.value?.role;
    if (s.name != null && !canAccess(s.name!, role)) {
      return MaterialPageRoute<dynamic>(
        settings: const RouteSettings(name: login),
        builder: (_) => const LoginScreen(),
      );
    }

    final Widget? page = switch (s.name) {
      splash => const SplashScreen(),
      login => const LoginScreen(),
      recover => const RecoverPasswordScreen(),
      accessContext => const AccessContextScreen(),
      // Técnico
      home => const MainShell(),
      lots => LotsScreen(
          initialFilter: s.arguments is LotsFilter ? s.arguments! as LotsFilter : LotsFilter.todos),
      lotDetail when s.arguments is String => LotDetailScreen(lotId: s.arguments! as String),
      identifyTrap => IdentifyTrapScreen(initialCode: s.arguments as String?),
      scanTrap => const ScanTrapScreen(),
      trapIdentified when s.arguments is TrapLookup => TrapIdentifiedScreen(lookup: s.arguments! as TrapLookup),
      registerReading when s.arguments is Trap => RegisterReadingScreen(trap: s.arguments! as Trap),
      evidence when s.arguments is PhotoFile => EvidenceScreen(photo: s.arguments! as PhotoFile),
      finishLot => const FinishLotScreen(),
      finishVisit => const FinishVisitScreen(),
      sync => const SyncScreen(),
      history => const HistoryScreen(),
      profilePhoto when s.arguments is PhotoFile => ProfilePhotoScreen(photo: s.arguments! as PhotoFile),
      profileNotifications => const NotificationSettingsScreen(),
      notifications => const NotificationsScreen(),
      // Productor
      producerHome => const ProducerShell(),
      producerApplication => const RegisterApplicationScreen(),
      producerHarvest => const RegisterHarvestScreen(),
      producerHarvestDone when s.arguments is HarvestReport =>
        HarvestSavedScreen(report: s.arguments! as HarvestReport),
      producerSync => const ProducerSyncScreen(),
      // Planificaciones recibidas (técnico y productor)
      planningList => PlanningListScreen(
          title: role == UserRole.productor ? 'Planificaciones' : 'Asignaciones',
          subtitle: role == UserRole.productor
              ? 'Planeaciones que te envió el agrónomo'
              : 'Lotes y fechas que te asignó el agrónomo',
        ),
      planningDetail when s.arguments is String =>
        PlanningDetailScreen(planningId: s.arguments! as String),
      planningReject when s.arguments is String =>
        RejectPlanningScreen(planningId: s.arguments! as String),
      documentViewer when s.arguments is Planning =>
        DocumentViewerScreen(planning: s.arguments! as Planning),
      // Agrónomo
      agronomistHome => const AgronomistShell(),
      agroRecords => const RecordsScreen(),
      agroRecordReview when s.arguments is String =>
        RecordReviewScreen(recordId: s.arguments! as String),
      agroRecordLots when s.arguments is String =>
        RecordLotsScreen(recordId: s.arguments! as String),
      agroRecordTraps when s.arguments is String =>
        RecordTrapsScreen(lotId: s.arguments! as String),
      agroRecordReading when s.arguments is String =>
        RecordReadingScreen(trapId: s.arguments! as String),
      agroLotInfo => const LotInfoScreen(),
      agroLotSummary => const LotSummaryScreen(),
      agroConfig => const AgronomistConfigScreen(),
      agroPlanningHub => const PlanningHubScreen(),
      agroPlanningTarget when s.arguments is PlanningTarget =>
        PlanningTargetHubScreen(target: s.arguments! as PlanningTarget),
      agroNewPlanning when s.arguments is Planning => NewPlanningWizardScreen(
          target: (s.arguments! as Planning).target,
          from: s.arguments! as Planning,
        ),
      agroNewPlanning when s.arguments is PlanningTarget =>
        NewPlanningWizardScreen(target: s.arguments! as PlanningTarget),
      agroMyPlannings => MyPlanningsScreen(target: s.arguments as PlanningTarget?),
      agroPlanningDetail when s.arguments is String =>
        CreatedPlanningDetailScreen(planningId: s.arguments! as String),
      _ => null,
    };
    if (page == null) return null;
    return MaterialPageRoute<dynamic>(settings: s, builder: (_) => page);
  }
}
