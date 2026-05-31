/**
 * @file reminder_history_mapper.ts
 * @description Implementación del mapper del historial de recordatorios.
 * Convierte entre ReminderHistoryDocument (MongoDB) y ReminderHistory (dominio).
 * @module Reminders
 * @layer Data
 *
 * @implements {IReminderHistoryMapper}
 * @injectable
 */

import { injectable } from 'inversify';
import type { IReminderHistoryMapper } from '../IMappers/IReminderHistoryMapper.js';
import { ReminderHistory, ReminderResult } from '../../domain/entities/ReminderHistory.js';
import { ReminderHistoryDocument } from '../datasources/mongodb/models/ReminderModel.js';
import type { ReminderHistoryResponseDTO } from '../../domain/dtos/reminders/reminder-response.dto.js';

/**
 * Mapper del historial de recordatorios.
 *
 * @implements {IReminderHistoryMapper}
 * @injectable
 */
@injectable()
export class ReminderHistoryMapper implements IReminderHistoryMapper {

  /**
   * Convierte un documento MongoDB a entidad ReminderHistory.
   *
   * @param doc — Documento de la colección 'reminder_history'.
   * @returns Entidad ReminderHistory.
   */
  toEntity(doc: ReminderHistoryDocument): ReminderHistory {
    return new ReminderHistory({
      id:             doc._id.toHexString(),
      reminderId:     doc.reminderId.toHexString(),
      processedAt:    doc.processedAt,
      result:         doc.result as ReminderResult,
      details:        doc.details,
      idempotencyKey: doc.idempotencyKey,
    });
  }

  /**
   * Convierte una entidad ReminderHistory al DTO de respuesta HTTP.
   *
   * @param entity — Entidad ReminderHistory.
   * @returns ReminderHistoryResponseDTO serializable.
   */
  toResponseDTO(entity: ReminderHistory): ReminderHistoryResponseDTO {
    return {
      id:             entity.id,
      reminderId:     entity.reminderId,
      processedAt:    entity.processedAt.toISOString(),
      result:         entity.result,
      details:        entity.details,
      idempotencyKey: entity.idempotencyKey,
    };
  }
}
