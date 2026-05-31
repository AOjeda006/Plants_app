/// @file i_notification_mapper.dart
/// @description Interfaz del mapper de notificaciones in-app.
/// Contrato NotificationModel ↔ AppNotification.
/// @module Reminders
/// @layer Data
library;

import '../../domain/entities/notification.dart';
import '../models/notification_model.dart';

/// Contrato de conversión entre el modelo de serialización y la entidad de dominio.
///
/// [injectable] registrar en container.dart como singleton.
abstract interface class INotificationMapper {
  /// Convierte un modelo de serialización a entidad de dominio.
  AppNotification toEntity(NotificationModel model);

  /// Convierte una entidad de dominio a modelo de serialización.
  NotificationModel toModel(AppNotification entity);
}
