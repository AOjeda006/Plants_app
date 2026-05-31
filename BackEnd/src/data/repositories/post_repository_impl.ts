/**
 * @file post_repository_impl.ts
 * @description Implementación concreta del repositorio de posts usando MongoDB.
 * Delega el mapeo entre PostDocument y Post al IPostMapper.
 * @module Community
 * @layer Data
 *
 * @implements {IPostRepository}
 * @injectable
 * @dependencies MongoDBConnection, IPostMapper
 */

import { injectable, inject } from 'inversify';
import { ObjectId, ClientSession } from 'mongodb';
import type { IPostRepository } from '../../domain/repositories/IPostRepository.js';
import type { IPostMapper } from '../IMappers/IPostMapper.js';
import { Post } from '../../domain/entities/Post.js';
import { MongoDBConnection } from '../datasources/mongodb/MongoDBConnection.js';
import { POST_COLLECTION, PostDocument } from '../datasources/mongodb/models/PostModel.js';
import { TYPES } from '../../core/types.js';
import { NotFoundException } from '../../core/exceptions/NotFoundException.js';
import { createLogger } from '../../core/logger.js';

const logger = createLogger('PostRepository');

/**
 * Repositorio de posts de la comunidad con MongoDB.
 *
 * @implements {IPostRepository}
 * @injectable
 * @dependencies MongoDBConnection, IPostMapper
 */
@injectable()
export class PostRepositoryImpl implements IPostRepository {
  constructor(
    @inject(TYPES.MongoDBConnection) private readonly db: MongoDBConnection,
    @inject(TYPES.IPostMapper)        private readonly mapper: IPostMapper,
  ) {}

  /**
   * Obtiene la colección de posts de la BD activa.
   * @private
   */
  private get collection() {
    return this.db.getDatabase().collection<PostDocument>(POST_COLLECTION);
  }

  /**
   * Obtiene el feed global de posts activos, ordenado por fecha descendente.
   *
   * @param page — Número de página (base 1).
   * @param limit — Elementos por página.
   * @returns Lista paginada de posts.
   */
  async findFeed(page: number, limit: number): Promise<Post[]> {
    const skip = (page - 1) * limit;

    const docs = await this.collection
      .find({ deletedAt: null })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .toArray();

    return docs.map(d => this.mapper.toEntity(d));
  }

  /**
   * Busca un post activo por su id.
   *
   * @param id — Id del post.
   * @returns Post encontrado o null.
   */
  async findById(id: string): Promise<Post | null> {
    if (!ObjectId.isValid(id)) return null;

    const doc = await this.collection.findOne({
      _id: new ObjectId(id),
      deletedAt: null,
    });

    return doc ? this.mapper.toEntity(doc) : null;
  }

  /**
   * Crea un nuevo post en la base de datos.
   *
   * @param post — Datos del post sin id.
   * @param session — Sesión de transacción opcional.
   * @returns Post creado con id asignado.
   */
  async create(post: Omit<Post, 'id' | 'isActive'>, session?: ClientSession): Promise<Post> {
    const _id = new ObjectId();
    const now = new Date();

    const toInsert: PostDocument = {
      _id,
      userId:        new ObjectId(post.userId),
      content:       post.content,
      image:         post.image,
      likesCount:    0,
      commentsCount: 0,
      seenBy:        [],
      createdAt:     now,
      updatedAt:     now,
      deletedAt:     null,
    };

    await this.collection.insertOne(toInsert, { session });
    logger.debug(`Post creado: ${_id.toHexString()}`);

    return this.mapper.toEntity(toInsert);
  }

  /**
   * Incrementa o decrementa el contador de likes de un post de forma atómica.
   *
   * @param id — Id del post.
   * @param delta — +1 para like, -1 para unlike.
   * @param session — Sesión de transacción opcional.
   * @throws {NotFoundException} Si el post no existe o está eliminado.
   */
  async incrementLikesCount(id: string, delta: 1 | -1, session?: ClientSession): Promise<void> {
    if (!ObjectId.isValid(id)) throw new NotFoundException('Post', id);

    // Prevenir contadores negativos: solo decrementar si likesCount > 0.
    const filter = delta < 0
      ? { _id: new ObjectId(id), deletedAt: null, likesCount: { $gt: 0 } }
      : { _id: new ObjectId(id), deletedAt: null };

    const result = await this.collection.updateOne(
      filter,
      { $inc: { likesCount: delta }, $set: { updatedAt: new Date() } },
      { session },
    );

    if (result.matchedCount === 0) throw new NotFoundException('Post', id);
    logger.debug(`Post ${id}: likesCount ${delta > 0 ? '+1' : '-1'}`);
  }

  /**
   * Incrementa o decrementa el contador de comentarios de un post de forma atómica.
   *
   * @param id — Id del post.
   * @param delta — +1 al añadir, -1 al borrar.
   * @param session — Sesión de transacción opcional.
   * @throws {NotFoundException} Si el post no existe o está eliminado.
   */
  async incrementCommentsCount(id: string, delta: 1 | -1, session?: ClientSession): Promise<void> {
    if (!ObjectId.isValid(id)) throw new NotFoundException('Post', id);

    // Prevenir contadores negativos: solo decrementar si commentsCount > 0.
    const filter = delta < 0
      ? { _id: new ObjectId(id), deletedAt: null, commentsCount: { $gt: 0 } }
      : { _id: new ObjectId(id), deletedAt: null };

    const result = await this.collection.updateOne(
      filter,
      { $inc: { commentsCount: delta }, $set: { updatedAt: new Date() } },
      { session },
    );

    if (result.matchedCount === 0) throw new NotFoundException('Post', id);
    logger.debug(`Post ${id}: commentsCount ${delta > 0 ? '+1' : '-1'}`);
  }

  /**
   * Soft-delete de un post individual.
   *
   * @param id — ID del post (hex string).
   */
  async softDelete(id: string): Promise<void> {
    if (!ObjectId.isValid(id)) return;

    const now = new Date();
    await this.collection.updateOne(
      { _id: new ObjectId(id), deletedAt: null },
      { $set: { deletedAt: now, updatedAt: now } },
    );
    logger.info(`softDelete: post ${id} eliminado`);
  }

  /**
   * Soft-delete masivo de todos los posts activos de un usuario.
   *
   * @param userId — ID del usuario (hex string).
   */
  async softDeleteByUserId(userId: string): Promise<void> {
    if (!ObjectId.isValid(userId)) return;

    const now = new Date();
    const result = await this.collection.updateMany(
      { userId: new ObjectId(userId), deletedAt: null },
      { $set: { deletedAt: now, updatedAt: now } },
    );

    logger.info(`softDeleteByUserId: ${result.modifiedCount} posts eliminados para usuario ${userId}`);
  }
}
