/**
 * @file reminder_history_repository_impl.ts
 * @description Implementación concreta del repositorio de historial de recordatorios.
 * @module Reminders
 * @layer Data
 *
 * @implements {IReminderHistoryRepository}
 * @injectable
 * @dependencies MongoDBConnection, IReminderHistoryMapper
 */

import { injectable, inject } from 'inversify';
import { ObjectId, ClientSession } from 'mongodb';
import type { IReminderHistoryRepository } from '../../domain/repositories/IReminderHistoryRepository.js';
import type { IReminderHistoryMapper } from '../IMappers/IReminderHistoryMapper.js';
import { ReminderHistory } from '../../domain/entities/ReminderHistory.js';
import { MongoDBConnection } from '../datasources/mongodb/MongoDBConnection.js';
import { REMINDER_HISTORY_COLLECTION, ReminderHistoryDocument } from '../datasources/mongodb/models/ReminderModel.js';
import { TYPES } from '../../core/types.js';
import { createLogger } from '../../core/logger.js';

const logger = createLogger('ReminderHistoryRepository');

/**
 * Repositorio de historial de recordatorios con MongoDB.
 *
 * @implements {IReminderHistoryRepository}
 * @injectable
 * @dependencies MongoDBConnection, IReminderHistoryMapper
 */
@injectable()
export class ReminderHistoryRepositoryImpl implements IReminderHistoryRepository {
  constructor(
    @inject(TYPES.MongoDBConnection)      private readonly db: MongoDBConnection,
    @inject(TYPES.IReminderHistoryMapper) private readonly mapper: IReminderHistoryMapper,
  ) {}

  private get collection() {
    return this.db.getDatabase().collection<ReminderHistoryDocument>(REMINDER_HISTORY_COLLECTION);
  }

  /**
   * Obtiene el historial de un recordatorio, ordenado del más reciente al más antiguo.
   *
   * @param reminderId — Id del recordatorio.
   * @returns Lista de entradas de historial.
   */
  async findByReminderId(reminderId: string): Promise<ReminderHistory[]> {
    if (!ObjectId.isValid(reminderId)) return [];

    const docs = await this.collection
      .find({ reminderId: new ObjectId(reminderId) })
      .sort({ processedAt: -1 })
      .toArray();

    return docs.map((d) => this.mapper.toEntity(d));
  }

  /**
   * Verifica si ya existe una entrada con la clave de idempotencia dada.
   * Previene procesamiento duplicado en reinicios del cron.
   *
   * @param idempotencyKey — Clave reminderId_YYYY-MM-DD.
   * @returns true si ya existe.
   */
  async exists(idempotencyKey: string): Promise<boolean> {
    const count = await this.collection.countDocuments({ idempotencyKey });
    return count > 0;
  }

  /**
   * Crea una nueva entrada en el historial.
   *
   * @param entry — Datos de la entrada sin id.
   * @param session — Sesión opcional.
   * @returns ReminderHistory creada.
   */
  async create(entry: Omit<ReminderHistory, 'id'>, session?: ClientSession): Promise<ReminderHistory> {
    const _id = new ObjectId();
    const doc: ReminderHistoryDocument = {
      _id,
      reminderId:     entry.reminderId ? new ObjectId(entry.reminderId) : new ObjectId(),
      processedAt:    entry.processedAt,
      result:         entry.result,
      details:        entry.details,
      idempotencyKey: entry.idempotencyKey,
    };

    await this.collection.insertOne(doc, { session });
    logger.debug(`ReminderHistory creado: ${_id.toHexString()} key=${entry.idempotencyKey} result=${entry.result}`);
    return this.mapper.toEntity(doc);
  }
}
