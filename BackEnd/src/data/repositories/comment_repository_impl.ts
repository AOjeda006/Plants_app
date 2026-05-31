/**
 * @file comment_repository_impl.ts
 * @description Implementación concreta del repositorio de comentarios usando MongoDB.
 * Delega el mapeo entre CommentDocument y Comment al ICommentMapper.
 * @module Community
 * @layer Data
 *
 * @implements {ICommentRepository}
 * @injectable
 * @dependencies MongoDBConnection, ICommentMapper
 */

import { injectable, inject } from 'inversify';
import { ObjectId, ClientSession } from 'mongodb';
import type { ICommentRepository } from '../../domain/repositories/ICommentRepository.js';
import type { ICommentMapper } from '../IMappers/ICommentMapper.js';
import { Comment } from '../../domain/entities/Comment.js';
import { MongoDBConnection } from '../datasources/mongodb/MongoDBConnection.js';
import { COMMENT_COLLECTION, CommentDocument } from '../datasources/mongodb/models/CommentModel.js';
import { TYPES } from '../../core/types.js';
import { createLogger } from '../../core/logger.js';

const logger = createLogger('CommentRepository');

/**
 * Repositorio de comentarios de posts con MongoDB.
 *
 * @implements {ICommentRepository}
 * @injectable
 * @dependencies MongoDBConnection, ICommentMapper
 */
@injectable()
export class CommentRepositoryImpl implements ICommentRepository {
  constructor(
    @inject(TYPES.MongoDBConnection) private readonly db: MongoDBConnection,
    @inject(TYPES.ICommentMapper)     private readonly mapper: ICommentMapper,
  ) {}

  /**
   * Obtiene la colección de comentarios de la BD activa.
   * @private
   */
  private get collection() {
    return this.db.getDatabase().collection<CommentDocument>(COMMENT_COLLECTION);
  }

  /**
   * Obtiene los comentarios activos de un post, ordenados por fecha ascendente.
   *
   * @param postId — Id del post.
   * @returns Lista de comentarios activos.
   */
  async findByPostId(postId: string): Promise<Comment[]> {
    if (!ObjectId.isValid(postId)) return [];

    const docs = await this.collection
      .find({ postId: new ObjectId(postId), deletedAt: null })
      .sort({ createdAt: 1 })
      .toArray();

    return docs.map(d => this.mapper.toEntity(d));
  }

  /**
   * Busca un comentario por su id (incluye borrados lógicamente).
   *
   * @param id — Id del comentario.
   * @returns Comentario encontrado o null.
   */
  async findById(id: string): Promise<Comment | null> {
    if (!ObjectId.isValid(id)) return null;

    const doc = await this.collection.findOne({ _id: new ObjectId(id) });
    return doc ? this.mapper.toEntity(doc) : null;
  }

  /**
   * Crea un nuevo comentario en la base de datos.
   *
   * @param postId — Id del post comentado.
   * @param userId — Id del autor.
   * @param content — Texto del comentario.
   * @param session — Sesión de transacción opcional.
   * @returns Comentario creado con id asignado.
   */
  async create(
    postId: string,
    userId: string,
    content: string,
    session?: ClientSession,
  ): Promise<Comment> {
    const docData = this.mapper.toDocument(postId, userId, content);
    const _id = new ObjectId();

    const toInsert: CommentDocument = { _id, ...docData };
    await this.collection.insertOne(toInsert, { session });
    logger.debug(`Comentario creado: ${_id.toHexString()} en post ${postId}`);

    return this.mapper.toEntity(toInsert);
  }

  /**
   * Obtiene todos los comentarios activos de un usuario.
   * Usado antes del soft-delete para saber cuántos comentarios tiene en cada post.
   *
   * @param userId — ID del usuario (hex string).
   * @returns Lista de comentarios activos.
   */
  async findActiveByUserId(userId: string): Promise<Comment[]> {
    if (!ObjectId.isValid(userId)) return [];

    const docs = await this.collection
      .find({ userId: new ObjectId(userId), deletedAt: null })
      .toArray();

    return docs.map(d => this.mapper.toEntity(d));
  }

  /**
   * Soft-delete de un comentario individual.
   *
   * @param id — ID del comentario (hex string).
   */
  async softDelete(id: string): Promise<void> {
    if (!ObjectId.isValid(id)) return;

    const now = new Date();
    await this.collection.updateOne(
      { _id: new ObjectId(id), deletedAt: null },
      { $set: { deletedAt: now } },
    );
    logger.info(`softDelete: comentario ${id} eliminado`);
  }

  /**
   * Soft-delete masivo de todos los comentarios activos de un usuario.
   *
   * @param userId — ID del usuario (hex string).
   */
  async softDeleteByUserId(userId: string): Promise<void> {
    if (!ObjectId.isValid(userId)) return;

    const now = new Date();
    const result = await this.collection.updateMany(
      { userId: new ObjectId(userId), deletedAt: null },
      { $set: { deletedAt: now } },
    );

    logger.info(`softDeleteByUserId: ${result.modifiedCount} comentarios eliminados para usuario ${userId}`);
  }
}
