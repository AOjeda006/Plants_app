/**
 * @file IReminderHistoryMapper.ts
 * @description Interfaz del mapper del historial de recordatorios.
 * @module Reminders
 * @layer Data
 */

import type { ReminderHistory } from '../../domain/entities/ReminderHistory.js';
import type { ReminderHistoryResponseDTO } from '../../domain/dtos/reminders/reminder-response.dto.js';
import type { ReminderHistoryDocument } from '../datasources/mongodb/models/ReminderModel.js';

export interface IReminderHistoryMapper {
  /**
   * Convierte un documento MongoDB en entidad de dominio.
   *
   * @param doc — Documento de la colección reminder_history.
   * @returns Entidad ReminderHistory.
   */
  toEntity(doc: ReminderHistoryDocument): ReminderHistory;

  /**
   * Convierte una entidad en DTO de respuesta HTTP.
   *
   * @param entity — Entidad ReminderHistory.
   * @returns ReminderHistoryResponseDTO.
   */
  toResponseDTO(entity: ReminderHistory): ReminderHistoryResponseDTO;
}
