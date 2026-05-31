/**
 * @file notification_repository_impl.ts
 * @description Implementación concreta del repositorio de notificaciones in-app usando MongoDB.
 * @module Reminders
 * @layer Data
 *
 * @implements {INotificationRepository}
 * @injectable
 * @dependencies MongoDBConnection, INotificationMapper
 */

import { injectable, inject } from 'inversify';
import { ObjectId } from 'mongodb';
import type { INotificationRepository } from '../../domain/repositories/INotificationRepository.js';
import type { INotificationMapper } from '../IMappers/INotificationMapper.js';
import { Notification } from '../../domain/entities/Notification.js';
import { MongoDBConnection } from '../datasources/mongodb/MongoDBConnection.js';
import { NOTIFICATION_COLLECTION, NotificationDocument } from '../datasources/mongodb/models/NotificationModel.js';
import { TYPES } from '../../core/types.js';
import { createLogger } from '../../core/logger.js';

const logger = createLogger('NotificationRepository');

/**
 * Repositorio de notificaciones in-app con MongoDB.
 *
 * @implements {INotificationRepository}
 * @injectable
 * @dependencies MongoDBConnection, INotificationMapper
 */
@injectable()
export class NotificationRepositoryImpl implements INotificationRepository {
  constructor(
    @inject(TYPES.MongoDBConnection)    private readonly db: MongoDBConnection,
    @inject(TYPES.INotificationMapper)  private readonly mapper: INotificationMapper,
  ) {}

  private get collection() {
    return this.db.getDatabase().collection<NotificationDocument>(NOTIFICATION_COLLECTION);
  }

  /**
   * Devuelve las notificaciones del usuario ordenadas por fecha descendente (más recientes primero).
   *
   * @param userId — Id del usuario.
   * @returns Lista de notificaciones.
   */
  async findByUserId(userId: string): Promise<Notification[]> {
    if (!ObjectId.isValid(userId)) return [];

    const docs = await this.collection
      .find({ userId: new ObjectId(userId) })
      .sort({ createdAt: -1 })
      .toArray();

    return docs.map((d) => this.mapper.toEntity(d));
  }

  /**
   * Inserta una nueva notificación en MongoDB.
   *
   * @param data — Datos de la notificación sin id (se genera un nuevo ObjectId).
   * @returns Notificación creada con su id asignado.
   */
  async create(data: Omit<Notification, 'id'>): Promise<Notification> {
    const doc: NotificationDocument = {
      _id:        new ObjectId(),
      userId:     new ObjectId(data.userId),
      type:       data.type,
      message:    data.message,
      reminderId: data.reminderId ? new ObjectId(data.reminderId) : undefined,
      plantId:    data.plantId ? new ObjectId(data.plantId) : undefined,
      isRead:     data.isRead,
      createdAt:  data.createdAt,
    };

    await this.collection.insertOne(doc);
    logger.debug(`Notificación creada: ${doc._id.toHexString()} (usuario ${data.userId})`);
    return this.mapper.toEntity(doc);
  }

  /**
   * Cuenta las notificaciones creadas hoy para un usuario.
   *
   * @param userId — Id del usuario.
   * @returns Número de notificaciones creadas hoy.
   */
  async countTodayByUserId(userId: string): Promise<number> {
    if (!ObjectId.isValid(userId)) return 0;

    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);

    return this.collection.countDocuments({
      userId:    new ObjectId(userId),
      createdAt: { $gte: startOfDay },
    });
  }

  /**
   * Marca todas las notificaciones de un usuario como leídas.
   *
   * @param userId — Id del usuario.
   */
  async markAllReadByUserId(userId: string): Promise<void> {
    if (!ObjectId.isValid(userId)) return;

    await this.collection.updateMany(
      { userId: new ObjectId(userId), isRead: false },
      { $set: { isRead: true } },
    );
    logger.debug(`Notificaciones marcadas como leídas para usuario ${userId}`);
  }

  /**
   * Marca como leídas las notificaciones con los ids indicados (del usuario).
   *
   * @param userId — Id del usuario.
   * @param ids — Ids de notificaciones a marcar.
   */
  async markReadByIds(userId: string, ids: string[]): Promise<void> {
    if (!ObjectId.isValid(userId) || ids.length === 0) return;

    const objectIds = ids.filter((id) => ObjectId.isValid(id)).map((id) => new ObjectId(id));
    if (objectIds.length === 0) return;

    await this.collection.updateMany(
      { _id: { $in: objectIds }, userId: new ObjectId(userId), isRead: false },
      { $set: { isRead: true } },
    );
    logger.debug(`Notificaciones marcadas como leídas por IDs para usuario ${userId}: ${objectIds.length}`);
  }

  /**
   * Elimina todas las notificaciones de un usuario.
   *
   * @param userId — Id del usuario.
   */
  async deleteAllByUserId(userId: string): Promise<void> {
    if (!ObjectId.isValid(userId)) return;

    const result = await this.collection.deleteMany({ userId: new ObjectId(userId) });
    logger.debug(`Notificaciones eliminadas para usuario ${userId}: ${result.deletedCount}`);
  }

  /**
   * Elimina las notificaciones con los ids indicados (del usuario).
   *
   * @param userId — Id del usuario.
   * @param ids — Ids de notificaciones a eliminar.
   */
  async deleteByIds(userId: string, ids: string[]): Promise<void> {
    if (!ObjectId.isValid(userId) || ids.length === 0) return;

    const objectIds = ids.filter((id) => ObjectId.isValid(id)).map((id) => new ObjectId(id));
    if (objectIds.length === 0) return;

    const result = await this.collection.deleteMany(
      { _id: { $in: objectIds }, userId: new ObjectId(userId) },
    );
    logger.debug(`Notificaciones eliminadas por IDs para usuario ${userId}: ${result.deletedCount}`);
  }
}
