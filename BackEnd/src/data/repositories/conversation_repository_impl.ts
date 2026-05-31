/**
 * @file conversation_repository_impl.ts
 * @description Implementación concreta del repositorio de conversaciones usando MongoDB.
 * Delega el mapeo entre ConversationDocument y Conversation al IConversationMapper.
 * @module Chat
 * @layer Data
 *
 * @implements {IConversationRepository}
 * @injectable
 * @dependencies MongoDBConnection, IConversationMapper
 */

import { injectable, inject } from 'inversify';
import { ObjectId, ClientSession } from 'mongodb';
import type { IConversationRepository } from '../../domain/repositories/IConversationRepository.js';
import type { IConversationMapper } from '../IMappers/IConversationMapper.js';
import { Conversation } from '../../domain/entities/Conversation.js';
import { MongoDBConnection } from '../datasources/mongodb/MongoDBConnection.js';
import { CONVERSATION_COLLECTION, ConversationDocument } from '../datasources/mongodb/models/ConversationModel.js';
import { TYPES } from '../../core/types.js';
import { createLogger } from '../../core/logger.js';

const logger = createLogger('ConversationRepository');

/**
 * Repositorio de conversaciones de chat con MongoDB.
 *
 * @implements {IConversationRepository}
 * @injectable
 * @dependencies MongoDBConnection, IConversationMapper
 */
@injectable()
export class ConversationRepositoryImpl implements IConversationRepository {
  constructor(
    @inject(TYPES.MongoDBConnection)    private readonly db: MongoDBConnection,
    @inject(TYPES.IConversationMapper)  private readonly mapper: IConversationMapper,
  ) {}

  /**
   * Obtiene la colección de conversaciones de la BD activa.
   * @private
   */
  private get collection() {
    return this.db.getDatabase().collection<ConversationDocument>(CONVERSATION_COLLECTION);
  }

  /**
   * Obtiene todas las conversaciones activas del usuario, ordenadas por actividad reciente.
   *
   * @param userId — ID del usuario participante.
   * @returns Lista de conversaciones del usuario.
   */
  async findByUserId(userId: string): Promise<Conversation[]> {
    if (!ObjectId.isValid(userId)) return [];

    const docs = await this.collection
      .find({
        participants: new ObjectId(userId),
        deletedAt: null,
      })
      .sort({ lastMessageAt: -1 })
      .toArray();

    return docs.map(d => this.mapper.toEntity(d));
  }

  /**
   * Busca una conversación por su ID.
   *
   * @param id — ID de la conversación.
   * @returns Conversación encontrada o null.
   */
  async findById(id: string): Promise<Conversation | null> {
    if (!ObjectId.isValid(id)) return null;

    const doc = await this.collection.findOne({ _id: new ObjectId(id), deletedAt: null });
    return doc ? this.mapper.toEntity(doc) : null;
  }

  /**
   * Busca una conversación 1-a-1 existente entre dos usuarios.
   * Usa $all para garantizar que ambos sean participantes.
   *
   * @param userIdA — ID del primer participante.
   * @param userIdB — ID del segundo participante.
   * @returns Conversación encontrada o null.
   */
  async findByParticipants(userIdA: string, userIdB: string): Promise<Conversation | null> {
    if (!ObjectId.isValid(userIdA) || !ObjectId.isValid(userIdB)) return null;

    const doc = await this.collection.findOne({
      participants: { $all: [new ObjectId(userIdA), new ObjectId(userIdB)] },
      deletedAt: null,
    });

    return doc ? this.mapper.toEntity(doc) : null;
  }

  /**
   * Crea una nueva conversación entre dos usuarios.
   *
   * @param participantA — ID del primer participante.
   * @param participantB — ID del segundo participante.
   * @param session — Sesión de transacción opcional.
   * @returns Conversación creada con id asignado.
   */
  async create(participantA: string, participantB: string, session?: ClientSession): Promise<Conversation> {
    const _id = new ObjectId();
    const now = new Date();

    const toInsert: ConversationDocument = {
      _id,
      participants:  [new ObjectId(participantA), new ObjectId(participantB)],
      lastMessageAt: undefined,
      createdAt:     now,
      updatedAt:     now,
      deletedAt:     null,
    };

    await this.collection.insertOne(toInsert, { session });
    logger.debug(`Conversación creada: ${_id.toHexString()} entre ${participantA} y ${participantB}`);

    return this.mapper.toEntity(toInsert);
  }

  /**
   * Actualiza la fecha del último mensaje de la conversación.
   *
   * @param id — ID de la conversación.
   * @param date — Fecha del nuevo mensaje.
   * @param session — Sesión de transacción opcional.
   */
  async updateLastMessageAt(id: string, date: Date, session?: ClientSession): Promise<void> {
    if (!ObjectId.isValid(id)) return;

    await this.collection.updateOne(
      { _id: new ObjectId(id) },
      { $set: { lastMessageAt: date, updatedAt: new Date() } },
      { session },
    );
    logger.debug(`Conversación ${id}: lastMessageAt actualizado`);
  }
}
