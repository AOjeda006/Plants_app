/**
 * @file comment_mapper.ts
 * @description Implementación del mapper de comentarios de posts.
 * Convierte entre CommentDocument (MongoDB), Comment (dominio) y CommentResponseDTO (presentación).
 * @module Community
 * @layer Data
 *
 * @implements {ICommentMapper}
 * @injectable
 */

import { injectable } from 'inversify';
import { ObjectId } from 'mongodb';
import type { ICommentMapper } from '../IMappers/ICommentMapper.js';
import { Comment } from '../../domain/entities/Comment.js';
import type { CommentDocument } from '../datasources/mongodb/models/CommentModel.js';
import type { CommentResponseDTO } from '../../domain/dtos/community/comment-response.dto.js';

/**
 * Mapper de comentarios de posts.
 *
 * @implements {ICommentMapper}
 * @injectable
 */
@injectable()
export class CommentMapper implements ICommentMapper {

  /**
   * Convierte un documento MongoDB a entidad Comment.
   *
   * @param doc — Documento de la colección 'comments'.
   * @returns Entidad Comment.
   */
  toEntity(doc: CommentDocument): Comment {
    return new Comment({
      id:        doc._id.toHexString(),
      postId:    doc.postId.toHexString(),
      userId:    doc.userId.toHexString(),
      content:   doc.content,
      createdAt: doc.createdAt,
      deletedAt: doc.deletedAt,
    });
  }

  /**
   * Construye un documento MongoDB para insertar un nuevo comentario (sin _id).
   *
   * @param postId — Id del post comentado (string hexadecimal).
   * @param userId — Id del autor (string hexadecimal).
   * @param content — Texto del comentario.
   * @returns Documento parcial para insertar en MongoDB.
   */
  toDocument(postId: string, userId: string, content: string): Omit<CommentDocument, '_id'> {
    return {
      postId:    new ObjectId(postId),
      userId:    new ObjectId(userId),
      content,
      createdAt: new Date(),
      deletedAt: null,
    };
  }

  /**
   * Convierte una entidad Comment al DTO de respuesta HTTP, enriquecido con datos del autor.
   *
   * @param entity — Entidad Comment.
   * @param authorName — Nombre del autor del comentario.
   * @param authorPhoto — URL de la foto del autor (opcional).
   * @returns CommentResponseDTO serializable.
   */
  toResponseDTO(entity: Comment, authorName: string, authorPhoto?: string): CommentResponseDTO {
    return {
      id:          entity.id,
      postId:      entity.postId,
      userId:      entity.userId,
      authorName,
      authorPhoto,
      content:     entity.content,
      createdAt:   entity.createdAt.toISOString(),
    };
  }
}
