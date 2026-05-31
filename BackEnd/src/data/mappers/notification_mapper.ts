/**
 * @file notification_mapper.ts
 * @description Implementación del mapper de notificaciones in-app.
 * Convierte entre NotificationDocument (MongoDB), Notification (dominio) y
 * NotificationResponseDTO (presentación).
 * @module Reminders
 * @layer Data
 *
 * @implements {INotificationMapper}
 * @injectable
 */

import { injectable } from 'inversify';
import { ObjectId } from 'mongodb';
import type { INotificationMapper } from '../IMappers/INotificationMapper.js';
import { Notification, NotificationType } from '../../domain/entities/Notification.js';
import type { NotificationDocument } from '../datasources/mongodb/models/NotificationModel.js';
import type { NotificationResponseDTO } from '../../domain/dtos/notifications/notification-response.dto.js';

/**
 * Mapper de notificaciones in-app.
 *
 * @implements {INotificationMapper}
 * @injectable
 */
@injectable()
export class NotificationMapper implements INotificationMapper {

  /**
   * Convierte un documento MongoDB a entidad Notification.
   *
   * @param doc — Documento de la colección 'notifications'.
   * @returns Entidad Notification.
   */
  toEntity(doc: NotificationDocument): Notification {
    return new Notification({
      id:         doc._id.toHexString(),
      userId:     doc.userId.toHexString(),
      type:       doc.type as NotificationType,
      message:    doc.message,
      reminderId: doc.reminderId?.toHexString(),
      plantId:    doc.plantId?.toHexString(),
      isRead:     doc.isRead,
      createdAt:  doc.createdAt,
    });
  }

  /**
   * Convierte una entidad Notification a documento MongoDB.
   *
   * @param entity — Entidad Notification.
   * @returns NotificationDocument para insertar/actualizar.
   */
  toDocument(entity: Notification): NotificationDocument {
    return {
      _id:        new ObjectId(entity.id),
      userId:     new ObjectId(entity.userId),
      type:       entity.type,
      message:    entity.message,
      reminderId: entity.reminderId ? new ObjectId(entity.reminderId) : undefined,
      plantId:    entity.plantId ? new ObjectId(entity.plantId) : undefined,
      isRead:     entity.isRead,
      createdAt:  entity.createdAt,
    };
  }

  /**
   * Convierte una entidad Notification al DTO de respuesta HTTP.
   *
   * @param entity — Entidad Notification.
   * @returns NotificationResponseDTO serializable.
   */
  toResponseDTO(entity: Notification): NotificationResponseDTO {
    return {
      id:         entity.id,
      userId:     entity.userId,
      type:       entity.type,
      message:    entity.message,
      reminderId: entity.reminderId,
      plantId:    entity.plantId,
      isRead:     entity.isRead,
      createdAt:  entity.createdAt.toISOString(),

    };
  }
}
