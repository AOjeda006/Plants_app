/// @file mark_notifications_read_use_case.dart
/// @description Caso de uso para marcar todas las notificaciones del usuario como leídas.
/// @module Reminders
/// @layer Domain
library;

import '../../interfaces/usecases/notifications/i_mark_notifications_read_use_case.dart';
import '../../repositories/i_notification_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// MARK NOTIFICATIONS READ USE CASE
// ═══════════════════════════════════════════════════════════════════════════════

/// Delega en [INotificationRepository.markAllRead].
///
/// [implements] IMarkNotificationsReadUseCase
/// [dependencies] INotificationRepository
class MarkNotificationsReadUseCase implements IMarkNotificationsReadUseCase {
  final INotificationRepository _repository;

  const MarkNotificationsReadUseCase({required INotificationRepository repository})
      : _repository = repository;

  @override
  Future<void> execute({List<String>? ids}) => _repository.markAllRead(ids: ids);
}
