/**
 * @file IGetUserRemindersUseCase.ts
 * @description Interfaz del caso de uso para obtener los recordatorios del usuario.
 * @module Reminders
 * @layer Domain
 */

import type { ReminderResponseDTO } from '../../../dtos/reminders/reminder-response.dto.js';

export interface IGetUserRemindersUseCase {
  /**
   * @param userId — Id del usuario autenticado.
   * @returns Lista de recordatorios activos ordenados por scheduledDate asc.
   */
  execute(userId: string): Promise<ReminderResponseDTO[]>;
}
