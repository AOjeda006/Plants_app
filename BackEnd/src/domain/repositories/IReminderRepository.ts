/**
 * @file IReminderRepository.ts
 * @description Interfaz del repositorio de recordatorios de cuidado.
 * @module Reminders
 * @layer Domain
 */

import type { Reminder } from '../entities/Reminder.js';
import type { ClientSession } from 'mongodb';

export interface IReminderRepository {
  /**
   * Obtiene todos los recordatorios activos de un usuario.
   *
   * @param userId — Id del usuario.
   * @returns Lista de recordatorios (completados y pendientes).
   */
  findByUserId(userId: string): Promise<Reminder[]>;

  /**
   * Obtiene todos los recordatorios pendientes de procesar
   * (scheduledDate <= ahora, isCompleted=false, suspended=false).
   *
   * @returns Lista de recordatorios vencidos pendientes.
   */
  findPending(): Promise<Reminder[]>;

  /**
   * Crea un nuevo recordatorio.
   *
   * @param reminder — Datos del recordatorio sin id.
   * @param session — Sesión de transacción opcional.
   * @returns Reminder creado.
   */
  create(reminder: Omit<Reminder, 'id' | 'isPending'>, session?: ClientSession): Promise<Reminder>;

  /**
   * Actualiza el estado y/o la fecha programada de un recordatorio.
   * Usado tras procesar el cron job para reprogramar o completar.
   *
   * @param id — Id del recordatorio.
   * @param status — Campos a actualizar.
   * @param session — Sesión de transacción opcional.
   */
  updateStatus(
    id: string,
    status: {
      isCompleted?:   boolean;
      suspended?:     boolean;
      attempts?:      number;
      scheduledDate?: Date;
    },
    session?: ClientSession,
  ): Promise<void>;

  /**
   * Elimina (soft delete o físico) todos los recordatorios de una planta.
   * Invocado cuando se elimina la planta.
   *
   * @param plantId — Id de la planta.
   * @param session — Sesión de transacción opcional.
   */
  deleteByPlantId(plantId: string, session?: ClientSession): Promise<void>;
}
