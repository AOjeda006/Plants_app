/// @file notification_mapper.dart
/// @description Implementación del mapper de notificaciones in-app.
/// Convierte NotificationModel ↔ AppNotification normalizando tipos y fechas.
/// @module Reminders
/// @layer Data
library;

import '../../core/utils/date_utils.dart';
import '../../domain/entities/notification.dart';
import '../i_mappers/i_notification_mapper.dart';
import '../models/notification_model.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// NOTIFICATION MAPPER
// ═══════════════════════════════════════════════════════════════════════════════

/// Implementación de [INotificationMapper].
///
/// [implements] INotificationMapper
/// [injectable] registrar en container.dart como singleton.
class NotificationMapper implements INotificationMapper {

  // ─── NotificationModel → AppNotification ─────────────────────────────────────

  @override
  AppNotification toEntity(NotificationModel model) {
    return AppNotification(
      id:         model.id,
      userId:     model.userId,
      type:       model.type,
      message:    model.message,
      reminderId: model.reminderId,
      plantId:    model.plantId,
      isRead:     model.isRead,
      createdAt:  PlantDateUtils.parseUtc(model.createdAt) ?? DateTime.now().toUtc(),
    );
  }

  // ─── AppNotification → NotificationModel ─────────────────────────────────────

  @override
  NotificationModel toModel(AppNotification entity) {
    return NotificationModel(
      id:         entity.id,
      userId:     entity.userId,
      type:       entity.type,
      message:    entity.message,
      reminderId: entity.reminderId,
      plantId:    entity.plantId,
      isRead:     entity.isRead,
      createdAt:  PlantDateUtils.toIso8601(entity.createdAt),
    );
  }
}
