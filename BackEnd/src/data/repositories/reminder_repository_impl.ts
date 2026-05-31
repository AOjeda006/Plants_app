/**
 * @file reminder_repository_impl.ts
 * @description Implementación concreta del repositorio de recordatorios usando MongoDB.
 * @module Reminders
 * @layer Data
 *
 * @implements {IReminderRepository}
 * @injectable
 * @dependencies MongoDBConnection, IReminderMapper
 */

import { injectable, inject } from 'inversify';
import { ObjectId, ClientSession } from 'mongodb';
import type { IReminderRepository } from '../../domain/repositories/IReminderRepository.js';
import type { IReminderMapper } from '../IMappers/IReminderMapper.js';
import { Reminder } from '../../domain/entities/Reminder.js';
import { MongoDBConnection } from '../datasources/mongodb/MongoDBConnection.js';
import { REMINDER_COLLECTION, ReminderDocument } from '../datasources/mongodb/models/ReminderModel.js';
import { TYPES } from '../../core/types.js';
import { NotFoundException } from '../../core/exceptions/NotFoundException.js';
import { createLogger } from '../../core/logger.js';

const logger = createLogger('ReminderRepository');

/**
 * Repositorio de recordatorios con MongoDB.
 *
 * @implements {IReminderRepository}
 * @injectable
 * @dependencies MongoDBConnection, IReminderMapper
 */
@injectable()
export class ReminderRepositoryImpl implements IReminderRepository {
  constructor(
    @inject(TYPES.MongoDBConnection)  private readonly db: MongoDBConnection,
    @inject(TYPES.IReminderMapper)    private readonly mapper: IReminderMapper,
  ) {}

  private get collection() {
    return this.db.getDatabase().collection<ReminderDocument>(REMINDER_COLLECTION);
  }

  /**
   * Obtiene todos los recordatorios no completados de un usuario, ordenados por fecha.
   *
   * @param userId — Id del usuario.
   * @returns Lista de recordatorios.
   */
  async findByUserId(userId: string): Promise<Reminder[]> {
    if (!ObjectId.isValid(userId)) return [];

    const docs = await this.collection
      .find({ userId: new ObjectId(userId), isCompleted: false })
      .sort({ scheduledDate: 1 })
      .toArray();

    return docs.map((d) => this.mapper.toEntity(d));
  }

  /**
   * Obtiene recordatorios vencidos no procesados (para el cron job).
   *
   * @returns Lista de recordatorios cuya scheduledDate <= ahora.
   */
  async findPending(): Promise<Reminder[]> {
    const now = new Date();
    const docs = await this.collection
      .find({
        scheduledDate: { $lte: now },
        isCompleted:   false,
        suspended:     false,
      })
      .toArray();

    return docs.map((d) => this.mapper.toEntity(d));
  }

  /**
   * Crea un nuevo recordatorio.
   *
   * @param reminder — Datos del recordatorio sin id.
   * @param session — Sesión opcional.
   * @returns Reminder creado.
   */
  async create(
    reminder: Omit<Reminder, 'id' | 'isPending'>,
    session?: ClientSession,
  ): Promise<Reminder> {
    const _id = new ObjectId();
    const doc: ReminderDocument = {
      _id,
      plantId:       new ObjectId(reminder.plantId),
      userId:        new ObjectId(reminder.userId),
      type:          reminder.type,
      scheduledDate: reminder.scheduledDate,
      message:       reminder.message,
      isCompleted:   reminder.isCompleted,
      suspended:     reminder.suspended,
      attempts:      reminder.attempts,
      createdAt:     reminder.createdAt,
    };

    await this.collection.insertOne(doc, { session });
    logger.debug(`Reminder creado: ${_id.toHexString()} tipo=${reminder.type}`);
    return this.mapper.toEntity(doc);
  }

  /**
   * Actualiza estado y/o fecha de reprogramación de un recordatorio.
   *
   * @param id — Id del recordatorio.
   * @param status — Campos a actualizar.
   * @param session — Sesión opcional.
   */
  async updateStatus(
    id: string,
    status: { isCompleted?: boolean; suspended?: boolean; attempts?: number; scheduledDate?: Date },
    session?: ClientSession,
  ): Promise<void> {
    if (!ObjectId.isValid(id)) throw new NotFoundException('Reminder', id);

    const result = await this.collection.updateOne(
      { _id: new ObjectId(id) },
      { $set: status },
      { session },
    );

    if (result.matchedCount === 0) throw new NotFoundException('Reminder', id);
    logger.debug(`Reminder actualizado: ${id} → ${JSON.stringify(status)}`);
  }

  /**
   * Elimina físicamente todos los recordatorios de una planta.
   * Se llama al eliminar la planta para mantener integridad.
   *
   * @param plantId — Id de la planta.
   * @param session — Sesión opcional.
   */
  async deleteByPlantId(plantId: string, session?: ClientSession): Promise<void> {
    if (!ObjectId.isValid(plantId)) return;

    const result = await this.collection.deleteMany(
      { plantId: new ObjectId(plantId) },
      { session },
    );

    logger.debug(`Reminders eliminados para planta ${plantId}: ${result.deletedCount}`);
  }
}
