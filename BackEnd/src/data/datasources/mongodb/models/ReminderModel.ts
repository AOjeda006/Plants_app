/**
 * @file ReminderModel.ts
 * @description Define los nombres de colección y tipos de documento MongoDB para
 * Reminder y ReminderHistory. SIN lógica de mapeo.
 * @module Reminders
 * @layer Data
 */

import { ObjectId } from 'mongodb';
import type { ReminderType } from '../../../../domain/entities/Reminder.js';
import type { ReminderResult } from '../../../../domain/entities/ReminderHistory.js';

/** Nombre de la colección de recordatorios */
export const REMINDER_COLLECTION = 'reminders';

/** Nombre de la colección de historial de recordatorios */
export const REMINDER_HISTORY_COLLECTION = 'reminder_history';

/**
 * Tipo del documento de Reminder en MongoDB.
 */
export interface ReminderDocument {
  _id:           ObjectId;
  plantId:       ObjectId;
  userId:        ObjectId;
  type:          ReminderType;
  scheduledDate: Date;
  message:       string;
  isCompleted:   boolean;
  suspended:     boolean;
  attempts:      number;
  createdAt:     Date;
}

/**
 * Tipo del documento de ReminderHistory en MongoDB.
 */
export interface ReminderHistoryDocument {
  _id:            ObjectId;
  reminderId:     ObjectId;
  processedAt:    Date;
  result:         ReminderResult;
  details?:       string;
  idempotencyKey: string;
}
