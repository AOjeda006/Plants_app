/// @file notification.dart
/// @description Entidad de dominio Notification.
/// Representa una notificación in-app generada por el cron de recordatorios.
/// @module Reminders
/// @layer Domain
library;

// ═══════════════════════════════════════════════════════════════════════════════
// NOTIFICATION ENTITY
// ═══════════════════════════════════════════════════════════════════════════════

/// Entidad de dominio que representa una notificación in-app.
///
/// Todos los campos son inmutables (final). Generada por el backend cuando
/// el cron job procesa un recordatorio de riego/poda/fertilización.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.message,
    required this.reminderId,
    required this.plantId,
    required this.isRead,
    required this.createdAt,
  });

  /// Identificador único (MongoDB ObjectId como String).
  final String id;

  /// ID del usuario destinatario.
  final String userId;

  /// Tipo de cuidado: 'watering', 'pruning', 'fertilizing', 'repotting', 'custom'.
  final String type;

  /// Mensaje descriptivo legible.
  final String message;

  /// ID del recordatorio que originó esta notificación (null en notificaciones generadas por el admin/cron de clima).
  final String? reminderId;

  /// ID de la planta asociada (null si la notificación no está vinculada a una planta concreta).
  final String? plantId;

  /// true si el usuario ya la ha visto / marcado como leída.
  final bool isRead;

  /// Fecha de creación (UTC).
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is AppNotification && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'AppNotification(id: $id, type: $type, isRead: $isRead)';
}
