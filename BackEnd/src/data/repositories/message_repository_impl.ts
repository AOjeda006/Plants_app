/**
 * @file message_repository_impl.ts
 * @description Implementación concreta del repositorio de mensajes usando MongoDB.
 * Delega el mapeo entre MessageDocument y Message al IMessageMapper.
 * @module Chat
 * @layer Data
 *
 * @implements {IMessageRepository}
 * @injectable
 * @dependencies MongoDBConnection, IMessageMapper
 */

import { injectable, inject } from 'inversify';
import { ObjectId, ClientSession } from 'mongodb';
import type { IMessageRepository, CreateMessageInput } from '../../domain/repositories/IMessageRepository.js';
import type { IMessageMapper } from '../IMappers/IMessageMapper.js';
import { Message, MessageStatus } from '../../domain/entities/Message.js';
import { MongoDBConnection } from '../datasources/mongodb/MongoDBConnection.js';
import { MESSAGE_COLLECTION, MessageDocument } from '../datasources/mongodb/models/MessageModel.js';
import { TYPES } from '../../core/types.js';
import { createLogger } from '../../core/logger.js';

const logger = createLogger('MessageRepository');

/**
 * Repositorio de mensajes de chat con MongoDB.
 *
 * @implements {IMessageRepository}
 * @injectable
 * @dependencies MongoDBConnection, IMessageMapper
 */
@injectable()
export class MessageRepositoryImpl implements IMessageRepository {
  constructor(
    @inject(TYPES.MongoDBConnection) private readonly db: MongoDBConnection,
    @inject(TYPES.IMessageMapper)    private readonly mapper: IMessageMapper,
  ) {}

  /**
   * Obtiene la colección de mensajes de la BD activa.
   * @private
   */
  private get collection() {
    return this.db.getDatabase().collection<MessageDocument>(MESSAGE_COLLECTION);
  }

  /**
   * Obtiene mensajes paginados de una conversación, ordenados por fecha descendente.
   *
   * @param conversationId — ID de la conversación.
   * @param page — Número de página (base 1). Por defecto 1.
   * @param limit — Elementos por página. Por defecto 30.
   * @returns Lista de mensajes.
   */
  async findByConversationId(conversationId: string, page = 1, limit = 30): Promise<Message[]> {
    if (!ObjectId.isValid(conversationId)) return [];

    const skip = (page - 1) * limit;
    const docs = await this.collection
      .find({ conversationId: new ObjectId(conversationId) })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .toArray();

    return docs.map(d => this.mapper.toEntity(d));
  }

  /**
   * Obtiene el último mensaje de una conversación.
   *
   * @param conversationId — ID de la conversación.
   * @returns Último mensaje o null si la conversación está vacía.
   */
  async findLastByConversationId(conversationId: string): Promise<Message | null> {
    if (!ObjectId.isValid(conversationId)) return null;

    const doc = await this.collection.findOne(
      { conversationId: new ObjectId(conversationId) },
      { sort: { createdAt: -1 } },
    );

    return doc ? this.mapper.toEntity(doc) : null;
  }

  /**
   * Busca un mensaje por su tempId de cliente para matching de ACK optimistas.
   *
   * @param tempId — ID temporal asignado por el cliente.
   * @returns Mensaje encontrado o null.
   */
  async findByTempId(tempId: string): Promise<Message | null> {
    const doc = await this.collection.findOne({ tempId });
    return doc ? this.mapper.toEntity(doc) : null;
  }

  /**
   * Crea y persiste un nuevo mensaje en la base de datos.
   *
   * @param input — Datos del mensaje agrupados (CreateMessageInput).
   * @param session — Sesión de transacción opcional.
   * @returns Mensaje creado con id asignado.
   */
  async create(input: CreateMessageInput, session?: ClientSession): Promise<Message> {
    const docData = this.mapper.toDocument(
      input.conversationId,
      input.senderId,
      input.receiverId,
      input.text,
      input.contentMeta,
      input.tempId,
    );
    const _id = new ObjectId();
    const toInsert: MessageDocument = { _id, ...docData };

    await this.collection.insertOne(toInsert, { session });
    logger.debug(`Mensaje creado: ${_id.toHexString()} en conversación ${input.conversationId}`);

    return this.mapper.toEntity(toInsert);
  }

  /**
   * Actualiza el estado de entrega de un mensaje.
   *
   * @param id — ID del mensaje.
   * @param status — Nuevo estado (pending → delivered → read).
   * @param session — Sesión de transacción opcional.
   */
  async updateStatus(id: string, status: MessageStatus, session?: ClientSession): Promise<void> {
    if (!ObjectId.isValid(id)) return;

    await this.collection.updateOne(
      { _id: new ObjectId(id) },
      { $set: { status, updatedAt: new Date() } },
      { session },
    );
    logger.debug(`Mensaje ${id}: estado → ${status}`);
  }

  /**
   * Marca todos los mensajes no leídos en una conversación como leídos para un usuario.
   * Solo afecta a mensajes no enviados por ese usuario.
   *
   * @param conversationId — ID de la conversación.
   * @param userId — ID del usuario que lee.
   * @param session — Sesión de transacción opcional.
   */
  async markAsRead(conversationId: string, userId: string, session?: ClientSession): Promise<void> {
    if (!ObjectId.isValid(conversationId) || !ObjectId.isValid(userId)) return;

    const result = await this.collection.updateMany(
      {
        conversationId: new ObjectId(conversationId),
        senderId: { $ne: new ObjectId(userId) },
        status: { $ne: 'read' },
      },
      { $set: { status: 'read', updatedAt: new Date() } },
      { session },
    );

    logger.debug(`Conversación ${conversationId}: ${result.modifiedCount} mensajes marcados como leídos por ${userId}`);
  }

  /**
   * Cuenta los mensajes no leídos en una conversación para un usuario.
   *
   * @param conversationId — ID de la conversación.
   * @param userId — ID del usuario que consulta.
   * @returns Número de mensajes no leídos.
   */
  async countUnread(conversationId: string, userId: string): Promise<number> {
    if (!ObjectId.isValid(conversationId) || !ObjectId.isValid(userId)) return 0;

    return this.collection.countDocuments({
      conversationId: new ObjectId(conversationId),
      senderId: { $ne: new ObjectId(userId) },
      status: { $ne: 'read' },
    });
  }

  /**
   * Devuelve los senderIds distintos de mensajes no leídos dirigidos al
   * receptor. Usado por SendMessageUseCase para decidir si el título del
   * push debe ser "[Nombre]" o "Varios usuarios".
   */
  async findDistinctUnreadSenderIds(receiverId: string): Promise<string[]> {
    if (!ObjectId.isValid(receiverId)) return [];

    const ids = await this.collection.distinct('senderId', {
      receiverId: new ObjectId(receiverId),
      status:     { $ne: 'read' },
    });
    return (ids as ObjectId[]).map((id) => id.toHexString());
  }
}
