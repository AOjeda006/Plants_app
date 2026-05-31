/**
 * @file post_like_repository_impl.ts
 * @description Implementación concreta del repositorio de likes de posts usando MongoDB.
 * @module Community
 * @layer Data
 *
 * @implements {IPostLikeRepository}
 * @injectable
 * @dependencies MongoDBConnection
 */

import { injectable, inject } from 'inversify';
import { ObjectId, ClientSession } from 'mongodb';
import type { IPostLikeRepository } from '../../domain/repositories/IPostLikeRepository.js';
import { PostLike } from '../../domain/entities/PostLike.js';
import { MongoDBConnection } from '../datasources/mongodb/MongoDBConnection.js';
import { POST_LIKE_COLLECTION, PostLikeDocument } from '../datasources/mongodb/models/PostLikeModel.js';
import { TYPES } from '../../core/types.js';
import { createLogger } from '../../core/logger.js';
import { ConflictException } from '../../core/exceptions/ConflictException.js';

const logger = createLogger('PostLikeRepository');

/**
 * Repositorio de likes de posts con MongoDB.
 * La unicidad (postId + userId) se garantiza mediante índice único en la colección.
 *
 * @implements {IPostLikeRepository}
 * @injectable
 * @dependencies MongoDBConnection
 */
@injectable()
export class PostLikeRepositoryImpl implements IPostLikeRepository {
  constructor(
    @inject(TYPES.MongoDBConnection) private readonly db: MongoDBConnection,
  ) {}

  /**
   * Obtiene la colección de likes de la BD activa.
   * @private
   */
  private get collection() {
    return this.db.getDatabase().collection<PostLikeDocument>(POST_LIKE_COLLECTION);
  }

  /**
   * Convierte un documento de like a entidad PostLike.
   * @private
   */
  private toEntity(doc: PostLikeDocument): PostLike {
    return new PostLike({
      id:        doc._id.toHexString(),
      postId:    doc.postId.toHexString(),
      userId:    doc.userId.toHexString(),
      createdAt: doc.createdAt,
    });
  }

  /**
   * Busca el like de un usuario concreto en un post concreto.
   *
   * @param postId — Id del post.
   * @param userId — Id del usuario.
   * @returns PostLike encontrado o null.
   */
  async findByPostAndUser(postId: string, userId: string): Promise<PostLike | null> {
    if (!ObjectId.isValid(postId) || !ObjectId.isValid(userId)) return null;

    const doc = await this.collection.findOne({
      postId: new ObjectId(postId),
      userId: new ObjectId(userId),
    });

    return doc ? this.toEntity(doc) : null;
  }

  /**
   * Registra un nuevo like. Si ya existe (carrera de condición), se ignora el duplicado.
   *
   * @param postId — Id del post.
   * @param userId — Id del usuario que da like.
   * @param session — Sesión de transacción opcional.
   * @returns PostLike creado.
   */
  async create(postId: string, userId: string, session?: ClientSession): Promise<PostLike> {
    const _id = new ObjectId();
    const doc: PostLikeDocument = {
      _id,
      postId:    new ObjectId(postId),
      userId:    new ObjectId(userId),
      createdAt: new Date(),
    };

    try {
      await this.collection.insertOne(doc, { session });
    } catch (error: unknown) {
      // Error 11000: clave duplicada — el like ya existe (race condition)
      if ((error as { code?: number }).code === 11000) {
        throw new ConflictException('Ya has dado like a este post.', 'LIKE_ALREADY_EXISTS');
      }
      throw error;
    }
    logger.debug(`Like registrado: post=${postId} user=${userId}`);

    return this.toEntity(doc);
  }

  /**
   * Elimina el like de un usuario en un post (borrado físico).
   *
   * @param postId — Id del post.
   * @param userId — Id del usuario.
   * @param session — Sesión de transacción opcional.
   */
  async delete(postId: string, userId: string, session?: ClientSession): Promise<void> {
    if (!ObjectId.isValid(postId) || !ObjectId.isValid(userId)) return;

    await this.collection.deleteOne(
      { postId: new ObjectId(postId), userId: new ObjectId(userId) },
      { session },
    );
    logger.debug(`Like eliminado: post=${postId} user=${userId}`);
  }
}
