/**
 * @file reminder-response.dto.ts
 * @description DTOs de respuesta para el módulo de recordatorios.
 * @module Reminders
 * @layer Domain
 */

import { ReminderType } from '../../entities/Reminder.js';
import { ReminderResult } from '../../entities/ReminderHistory.js';

/**
 * DTO de respuesta para un recordatorio individual.
 */
export interface ReminderResponseDTO {
  id:            string;
  plantId:       string;
  userId:        string;
  type:          ReminderType;
  scheduledDate: string;   // ISO 8601
  message:       string;
  isCompleted:   boolean;
  suspended:     boolean;
  attempts:      number;
  createdAt:     string;   // ISO 8601
  /** Indica si el recordatorio está pendiente de procesar (computed). */
  isPending:     boolean;
}

/**
 * DTO de respuesta para una entrada del historial de un recordatorio.
 */
export interface ReminderHistoryResponseDTO {
  id:             string;
  reminderId:     string;
  processedAt:    string;  // ISO 8601
  result:         ReminderResult;
  details?:       string;
  idempotencyKey: string;
}
