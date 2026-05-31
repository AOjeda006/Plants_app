/**
 * @file NotificationModel.ts
 * @description Define el nombre de colección y el tipo de documento MongoDB
 * para las notificaciones in-app. SIN lógica de mapeo.
 * @module Reminders
 * @layer Data
 */

import { ObjectId } from 'mongodb';
import type { NotificationType } from '../../../../domain/entities/Notification.js';

/** Nombre de la colección de notificaciones */
export const NOTIFICATION_COLLECTION = 'notifications';

/**
 * Tipo del documento de Notification en MongoDB.
 */
export interface NotificationDocument {
  _id:        ObjectId;
  userId:     ObjectId;
  type:       NotificationType;
  message:    string;
  reminderId?: ObjectId;
  plantId?:   ObjectId;
  isRead:     boolean;
  createdAt:  Date;
}
