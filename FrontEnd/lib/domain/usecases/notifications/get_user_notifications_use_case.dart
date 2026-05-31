/// @file get_user_notifications_use_case.dart
/// @description Caso de uso para obtener las notificaciones in-app del usuario.
/// @module Reminders
/// @layer Domain
library;

import '../../entities/notification.dart';
import '../../interfaces/usecases/notifications/i_get_user_notifications_use_case.dart';
import '../../repositories/i_notification_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// GET USER NOTIFICATIONS USE CASE
// ═══════════════════════════════════════════════════════════════════════════════

/// Delega en [INotificationRepository] para obtener las notificaciones del usuario.
///
/// [implements] IGetUserNotificationsUseCase
/// [dependencies] INotificationRepository
class GetUserNotificationsUseCase implements IGetUserNotificationsUseCase {
  final INotificationRepository _repository;

  const GetUserNotificationsUseCase({required INotificationRepository repository})
      : _repository = repository;

  @override
  Future<List<AppNotification>> execute() => _repository.getUserNotifications();
}
