/**
 * @file INotificationMapper.ts
 * @description Interfaz del mapper de notificaciones in-app.
 * @module Reminders
 * @layer Data
 */

import type { Notification } from '../../domain/entities/Notification.js';
import type { NotificationResponseDTO } from '../../domain/dtos/notifications/notification-response.dto.js';
import type { NotificationDocument } from '../datasources/mongodb/models/NotificationModel.js';

export interface INotificationMapper {
  /**
   * Convierte un documento MongoDB en entidad de dominio.
   *
   * @param doc — Documento de la colección notifications.
   * @returns Entidad Notification.
   */
  toEntity(doc: NotificationDocument): Notification;

  /**
   * Convierte una entidad en documento listo para MongoDB.
   *
   * @param entity — Entidad Notification.
   * @returns NotificationDocument.
   */
  toDocument(entity: Notification): NotificationDocument;

  /**
   * Convierte una entidad en DTO de respuesta HTTP.
   *
   * @param entity — Entidad Notification.
   * @returns NotificationResponseDTO.
   */
  toResponseDTO(entity: Notification): NotificationResponseDTO;
}
