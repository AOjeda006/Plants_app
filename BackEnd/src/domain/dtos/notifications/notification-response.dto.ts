/**
 * @file notification-response.dto.ts
 * @description DTO de respuesta HTTP para una notificación in-app.
 * @module Reminders
 * @layer Domain
 */

import type { NotificationType } from '../../entities/Notification.js';

/**
 * DTO enviado al cliente cuando lista sus notificaciones.
 */
export interface NotificationResponseDTO {
  id:         string;
  userId:     string;
  type:       NotificationType;
  message:    string;
  reminderId?: string;
  plantId?:   string;
  isRead:     boolean;
  createdAt:  string; // ISO 8601
}
