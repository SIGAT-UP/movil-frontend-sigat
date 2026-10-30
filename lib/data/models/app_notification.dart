
import 'user_profile.dart';

/// A dónde lleva un aviso al abrirlo.
class NotificationTarget {
  const NotificationTarget({required this.route, this.argument});

  final String route;
  final String? argument;

  factory NotificationTarget.fromJson(Map<String, dynamic> j) =>
      NotificationTarget(
        route: j['route'] as String,
        argument: j['argument'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'route': route,
        'argument': argument,
      };
}

/// Aviso dirigido a un usuario concreto.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.recipientUserId,
    required this.category,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
    this.target,
  });

  final String id;
  final String recipientUserId;
  final NotificationCategory category;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;
  final NotificationTarget? target;

  /// Convierte una notificación recibida desde el backend.
  factory AppNotification.fromApi(
    Map<String, dynamic> j, {
    required String userId,
    String? Function(String ruta)? routeFor,
  }) {
    final destino = j['destino'] as Map<String, dynamic>?;
    final ruta = destino == null
        ? null
        : routeFor?.call(destino['ruta'] as String);

    return AppNotification(
      id: j['noti_id'].toString(),
      recipientUserId: userId,
      category: NotificationCategory.fromApi(
        j['categoria'] as String?,
      ),
      title: j['titulo'] as String,
      body: j['cuerpo'] as String,
      createdAt: DateTime.parse(
        j['creada_en'] as String,
      ).toLocal(),
      read: j['leida'] as bool? ?? false,
      target: ruta == null
          ? null
          : NotificationTarget(
              route: ruta,
              argument: destino?['argumento'] as String?,
            ),
    );
  }

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        recipientUserId: recipientUserId,
        category: category,
        title: title,
        body: body,
        createdAt: createdAt,
        read: read ?? this.read,
        target: target,
      );

  factory AppNotification.fromJson(Map<String, dynamic> j) =>
      AppNotification(
        id: j['id'].toString(),
        recipientUserId: j['recipient_user_id'].toString(),
        category: NotificationCategory.values.firstWhere(
          (c) => c.name == j['category'],
          orElse: () => NotificationCategory.avisosPredio,
        ),
        title: j['title'] as String,
        body: j['body'] as String,
        createdAt: DateTime.parse(j['created_at'] as String),
        read: j['read'] as bool? ?? false,
        target: j['target'] == null
            ? null
            : NotificationTarget.fromJson(
                j['target'] as Map<String, dynamic>,
              ),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'recipient_user_id': recipientUserId,
        'category': category.name,
        'title': title,
        'body': body,
        'created_at': createdAt.toIso8601String(),
        'read': read,
        'target': target?.toJson(),
      };
}
