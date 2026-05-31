/**
 * @file post_mapper.ts
 * @description Implementación del mapper de posts de la comunidad.
 * Convierte entre PostDocument (MongoDB), Post (dominio) y PostResponseDTO (presentación).
 * @module Community
 * @layer Data
 *
 * @implements {IPostMapper}
 * @injectable
 */

import { injectable } from 'inversify';
import { ObjectId } from 'mongodb';
import type { IPostMapper } from '../IMappers/IPostMapper.js';
import { Post } from '../../domain/entities/Post.js';
import type { PostDocument } from '../datasources/mongodb/models/PostModel.js';
import type { PostResponseDTO } from '../../domain/dtos/community/post-response.dto.js';

/**
 * Mapper de posts de la comunidad.
 *
 * @implements {IPostMapper}
 * @injectable
 */
@injectable()
export class PostMapper implements IPostMapper {

  /**
   * Convierte un documento MongoDB a entidad Post.
   *
   * @param doc — Documento de la colección 'posts'.
   * @returns Entidad Post.
   */
  toEntity(doc: PostDocument): Post {
    return new Post({
      id:            doc._id.toHexString(),
      userId:        doc.userId.toHexString(),
      content:       doc.content,
      image:         doc.image,
      likesCount:    doc.likesCount,
      commentsCount: doc.commentsCount,
      seenBy:        doc.seenBy?.map(id => id.toHexString()) ?? [],
      createdAt:     doc.createdAt,
      updatedAt:     doc.updatedAt,
      deletedAt:     doc.deletedAt,
    });
  }

  /**
   * Convierte una entidad Post (sin id) a documento MongoDB (sin _id).
   *
   * @param entity — Datos del post sin id.
   * @returns Documento parcial para insertar en MongoDB.
   */
  toDocument(entity: Omit<Post, 'id' | 'isActive'>): Omit<PostDocument, '_id'> {
    return {
      userId:        new ObjectId(entity.userId),
      content:       entity.content,
      image:         entity.image,
      likesCount:    entity.likesCount,
      commentsCount: entity.commentsCount,
      seenBy:        entity.seenBy.map(id => new ObjectId(id)),
      createdAt:     entity.createdAt,
      updatedAt:     entity.updatedAt,
      deletedAt:     entity.deletedAt,
    };
  }

  /**
   * Convierte una entidad Post al DTO de respuesta HTTP, enriquecido con datos del autor.
   *
   * @param entity      — Entidad Post.
   * @param authorName  — Nombre del autor del post.
   * @param authorPhoto — URL de la foto del autor (opcional).
   * @param isLikedByMe — true si el usuario que solicita ya dio like (por defecto false).
   * @returns PostResponseDTO serializable.
   */
  toResponseDTO(entity: Post, authorName: string, authorPhoto?: string, isLikedByMe = false): PostResponseDTO {
    return {
      id:            entity.id,
      userId:        entity.userId,
      authorName,
      authorPhoto,
      content:       entity.content,
      image:         entity.image,
      likesCount:    entity.likesCount,
      commentsCount: entity.commentsCount,
      isLikedByMe,
      createdAt:     entity.createdAt.toISOString(),
      updatedAt:     entity.updatedAt.toISOString(),
    };
  }
}
