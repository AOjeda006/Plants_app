/// @file delete_notifications_use_case.dart
/// @description Caso de uso para eliminar todas las notificaciones del usuario.
/// @module Reminders
/// @layer Domain
library;

import '../../interfaces/usecases/notifications/i_delete_notifications_use_case.dart';
import '../../repositories/i_notification_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// DELETE NOTIFICATIONS USE CASE
// ═══════════════════════════════════════════════════════════════════════════════

/// Delega en [INotificationRepository.deleteAll].
///
/// [implements] IDeleteNotificationsUseCase
/// [dependencies] INotificationRepository
class DeleteNotificationsUseCase implements IDeleteNotificationsUseCase {
  final INotificationRepository _repository;

  const DeleteNotificationsUseCase({required INotificationRepository repository})
      : _repository = repository;

  @override
  Future<void> execute({List<String>? ids}) => _repository.deleteAll(ids: ids);
}
