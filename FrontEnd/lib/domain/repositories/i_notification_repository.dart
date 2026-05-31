/// @file i_notification_repository.dart
/// @description Interfaz del repositorio de notificaciones in-app.
/// Define el contrato que los use cases usan para acceder a los datos.
/// La implementación concreta (NotificationRepositoryImpl) vive en data/.
/// @module Reminders
/// @layer Domain
library;

import '../entities/notification.dart';

/// Contrato del repositorio de notificaciones in-app.
///
/// Los use cases dependen de esta interfaz, nunca de la implementación concreta.
abstract interface class INotificationRepository {
  /// Devuelve las notificaciones del usuario autenticado, ordenadas por fecha descendente.
  ///
  /// [throws] AppError si hay error de red o el token es inválido.
  Future<List<AppNotification>> getUserNotifications();

  /// Marca notificaciones del usuario como leídas.
  /// Si se proporcionan [ids], solo marca esas; si no, marca todas.
  ///
  /// [throws] AppError si hay error de red.
  Future<void> markAllRead({List<String>? ids});

  /// Elimina notificaciones del usuario.
  /// Si se proporcionan [ids], solo elimina esas; si no, elimina todas.
  ///
  /// [throws] AppError si hay error de red.
  Future<void> deleteAll({List<String>? ids});
}
