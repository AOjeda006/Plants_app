/**
 * @file IReminderHistoryRepository.ts
 * @description Interfaz del repositorio de historial de recordatorios.
 * @module Reminders
 * @layer Domain
 */

import type { ReminderHistory } from '../entities/ReminderHistory.js';
import type { ClientSession } from 'mongodb';

export interface IReminderHistoryRepository {
  /**
   * Obtiene el historial de procesamiento de un recordatorio.
   *
   * @param reminderId — Id del recordatorio.
   * @returns Lista de entradas de historial ordenadas por processedAt desc.
   */
  findByReminderId(reminderId: string): Promise<ReminderHistory[]>;

  /**
   * Verifica si ya existe una entrada de historial para una clave de idempotencia.
   * Previene el procesamiento duplicado en el cron job.
   *
   * @param idempotencyKey — Clave única (reminderId_YYYY-MM-DD).
   * @returns true si ya fue procesado.
   */
  exists(idempotencyKey: string): Promise<boolean>;

  /**
   * Crea una nueva entrada en el historial de recordatorios.
   *
   * @param entry — Datos de la entrada sin id.
   * @param session — Sesión de transacción opcional.
   * @returns ReminderHistory creada.
   */
  create(entry: Omit<ReminderHistory, 'id'>, session?: ClientSession): Promise<ReminderHistory>;
}
