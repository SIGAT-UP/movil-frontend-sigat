import 'dart:typed_data';

import 'photo_file.dart';

/// Categorías de aviso previstas para el proyecto.
/// Hoy la app solo usa el interruptor general [NotificationPreferences.enabled];
/// las categorías sirven para clasificar los avisos y para que, cuando el
/// backend las envíe, cada una pueda activarse por separado sin rehacer el
/// modelo ni la pantalla.
enum NotificationCategory {
  /// Se te asignó un lote, una inspección o una actividad.
  asignacion('Asignaciones'),
  alertasFitosanitarias('Alertas fitosanitarias'),
  recordatoriosInspeccion('Recordatorios de inspección'),
  avisosPredio('Avisos del predio asignado'),
  sincronizacion('Notificaciones de sincronización'),

  /// Solicitudes de contraseña nueva (le llegan al administrador).
  solicitudesCuenta('Solicitudes de cuenta');

  const NotificationCategory(this.label);
  final String label;

  /// `categoria` del backend (`alertas_fitosanitarias`…) → valor de la app.
  static NotificationCategory fromApi(String? codigo) {
    final camel = (codigo ?? '').replaceAllMapped(RegExp(r'_([a-z])'), (m) => m[1]!.toUpperCase());
    return NotificationCategory.values.firstWhere((c) => c.name == camel, orElse: () => NotificationCategory.avisosPredio);
  }
}

/// Preferencia de notificaciones DEL USUARIO.
///
/// Es distinta del permiso del sistema operativo: esto expresa si la persona
/// quiere recibir notificaciones de la app; que Android, iOS o el navegador
/// permitan mostrarlas es otra cosa y se consultará aparte cuando exista el
/// envío de notificaciones push.
class NotificationPreferences {
  const NotificationPreferences({this.enabled = true, this.categories = const {}});

  /// Interruptor general. Es el único que la app usa hoy.
  final bool enabled;

  /// Preparado para el futuro. Vacío = se asume lo que diga [enabled].
  final Map<NotificationCategory, bool> categories;

  String get label => enabled ? 'Activadas' : 'Desactivadas';

  NotificationPreferences copyWith({bool? enabled, Map<NotificationCategory, bool>? categories}) =>
      NotificationPreferences(enabled: enabled ?? this.enabled, categories: categories ?? this.categories);

  factory NotificationPreferences.fromJson(Map<String, dynamic> j) => NotificationPreferences(
        enabled: j['enabled'] as bool? ?? true,
        categories: {
          for (final c in NotificationCategory.values)
            if ((j['categories'] as Map?)?.containsKey(c.name) ?? false)
              c: (j['categories'] as Map)[c.name] as bool,
        },
      );

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'categories': {for (final e in categories.entries) e.key.name: e.value},
      };
}

/// Datos editables del usuario: fotografía y preferencias.
/// Pertenecen al usuario autenticado; cada cuenta tiene el suyo.
class UserProfile {
  const UserProfile({
    required this.userId,
    this.photoBytes,
    this.photoLocalPath,
    this.photoRemoteRef,
    this.photoStatus,
    this.notifications = const NotificationPreferences(),
  });

  final String userId;

  /// Contenido de la foto para mostrarla. Null = se usa el avatar con iniciales.
  final Uint8List? photoBytes;

  /// Ruta del archivo en el dispositivo. Hoy es la que entrega la cámara o la
  /// galería y puede ser temporal: NO es una referencia permanente.
  final String? photoLocalPath;

  /// Referencia devuelta por el servidor. Null = todavía no se ha subido.
  final String? photoRemoteRef;

  /// Null = no hay foto. [UploadStatus.local] = guardada solo en el dispositivo.
  final UploadStatus? photoStatus;

  final NotificationPreferences notifications;

  bool get hasPhoto => photoBytes != null || photoRemoteRef != null;
  bool get photoPendingUpload => photoStatus == UploadStatus.local || photoStatus == UploadStatus.failed;

  UserProfile copyWith({
    Uint8List? photoBytes,
    String? photoLocalPath,
    String? photoRemoteRef,
    UploadStatus? photoStatus,
    NotificationPreferences? notifications,
    bool clearPhoto = false,
  }) =>
      UserProfile(
        userId: userId,
        photoBytes: clearPhoto ? null : (photoBytes ?? this.photoBytes),
        photoLocalPath: clearPhoto ? null : (photoLocalPath ?? this.photoLocalPath),
        photoRemoteRef: clearPhoto ? null : (photoRemoteRef ?? this.photoRemoteRef),
        photoStatus: clearPhoto ? null : (photoStatus ?? this.photoStatus),
        notifications: notifications ?? this.notifications,
      );

  /// El backend entregará la foto como URL; `photoBytes` se descarga aparte.
  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        userId: j['user_id'].toString(),
        photoRemoteRef: j['photo_url'] as String?,
        photoStatus: j['photo_url'] == null ? null : UploadStatus.uploaded,
        notifications: j['notifications'] == null
            ? const NotificationPreferences()
            : NotificationPreferences.fromJson(j['notifications'] as Map<String, dynamic>),
      );
}
