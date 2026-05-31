/**
 * @file IReminderMapper.ts
 * @description Interfaz del mapper de recordatorios de riego.
 * @module Reminders
 * @layer Data
 */

import type { Reminder } from '../../domain/entities/Reminder.js';
import type { ReminderResponseDTO } from '../../domain/dtos/reminders/reminder-response.dto.js';
import type { ReminderDocument } from '../datasources/mongodb/models/ReminderModel.js';

export interface IReminderMapper {
  /**
   * Convierte un documento MongoDB en entidad de dominio.
   *
   * @param doc — Documento de la colección reminders.
   * @returns Entidad Reminder.
   */
  toEntity(doc: ReminderDocument): Reminder;

  /**
   * Convierte una entidad en documento listo para MongoDB.
   *
   * @param entity — Entidad Reminder.
   * @returns ReminderDocument.
   */
  toDocument(entity: Reminder): ReminderDocument;

  /**
   * Convierte una entidad en DTO de respuesta HTTP.
   *
   * @param entity — Entidad Reminder.
   * @returns ReminderResponseDTO.
   */
  toResponseDTO(entity: Reminder): ReminderResponseDTO;
}
