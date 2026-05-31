/**
 * @file reminder_mapper.ts
 * @description Implementación del mapper de recordatorios de riego.
 * Convierte entre ReminderDocument (MongoDB), Reminder (dominio) y ReminderResponseDTO (presentación).
 * @module Reminders
 * @layer Data
 *
 * @implements {IReminderMapper}
 * @injectable
 */

import { injectable } from 'inversify';
import { ObjectId } from 'mongodb';
import type { IReminderMapper } from '../IMappers/IReminderMapper.js';
import { Reminder, ReminderType } from '../../domain/entities/Reminder.js';
import { ReminderDocument } from '../datasources/mongodb/models/ReminderModel.js';
import type { ReminderResponseDTO } from '../../domain/dtos/reminders/reminder-response.dto.js';

/**
 * Mapper de recordatorios de riego.
 *
 * @implements {IReminderMapper}
 * @injectable
 */
@injectable()
export class ReminderMapper implements IReminderMapper {

  /**
   * Convierte un documento MongoDB a entidad Reminder.
   *
   * @param doc — Documento de la colección 'reminders'.
   * @returns Entidad Reminder.
   */
  toEntity(doc: ReminderDocument): Reminder {
    return new Reminder({
      id:            doc._id.toHexString(),
      plantId:       doc.plantId.toHexString(),
      userId:        doc.userId.toHexString(),
      type:          doc.type as ReminderType,
      scheduledDate: doc.scheduledDate,
      message:       doc.message,
      isCompleted:   doc.isCompleted,
      suspended:     doc.suspended,
      attempts:      doc.attempts,
      createdAt:     doc.createdAt,
    });
  }

  /**
   * Convierte una entidad Reminder a documento MongoDB.
   *
   * @param entity — Entidad Reminder.
   * @returns ReminderDocument para insertar/actualizar.
   */
  toDocument(entity: Reminder): ReminderDocument {
    return {
      _id:           new ObjectId(entity.id),
      plantId:       new ObjectId(entity.plantId),
      userId:        new ObjectId(entity.userId),
      type:          entity.type,
      scheduledDate: entity.scheduledDate,
      message:       entity.message,
      isCompleted:   entity.isCompleted,
      suspended:     entity.suspended,
      attempts:      entity.attempts,
      createdAt:     entity.createdAt,
    };
  }

  /**
   * Convierte una entidad Reminder al DTO de respuesta HTTP.
   *
   * @param entity — Entidad Reminder.
   * @returns ReminderResponseDTO serializable.
   */
  toResponseDTO(entity: Reminder): ReminderResponseDTO {
    return {
      id:            entity.id,
      plantId:       entity.plantId,
      userId:        entity.userId,
      type:          entity.type,
      scheduledDate: entity.scheduledDate.toISOString(),
      message:       entity.message,
      isCompleted:   entity.isCompleted,
      suspended:     entity.suspended,
      attempts:      entity.attempts,
      createdAt:     entity.createdAt.toISOString(),
      isPending:     entity.isPending,
    };
  }
}
