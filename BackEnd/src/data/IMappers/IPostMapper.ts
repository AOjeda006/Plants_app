/**
 * @file IPostMapper.ts
 * @description Interfaz del mapper de posts de la comunidad.
 * Define el contrato de transformación entre documento MongoDB, entidad de dominio y DTO de respuesta.
 * @module Community
 * @layer Data
 */

import type { Post } from '../../domain/entities/Post.js';
import type { PostDocument } from '../datasources/mongodb/models/PostModel.js';
import type { PostResponseDTO } from '../../domain/dtos/community/post-response.dto.js';

/**
 * Contrato del mapper de posts.
 * Los repositorios dependen de esta interfaz, no de la implementación concreta.
 */
export interface IPostMapper {
  /**
   * Convierte un documento MongoDB a entidad Post de dominio.
   *
   * @param doc — Documento de la colección 'posts'.
   * @returns Entidad Post.
   */
  toEntity(doc: PostDocument): Post;

  /**
   * Convierte una entidad Post a documento MongoDB (sin _id).
   *
   * @param entity — Entidad Post.
   * @returns Documento parcial para insertar en MongoDB.
   */
  toDocument(entity: Omit<Post, 'id' | 'isActive'>): Omit<PostDocument, '_id'>;

  /**
   * Convierte una entidad Post al DTO de respuesta HTTP, enriquecido con datos del autor.
   *
   * @param entity      — Entidad Post.
   * @param authorName  — Nombre del autor del post.
   * @param authorPhoto — URL de la foto del autor (opcional).
   * @param isLikedByMe — true si el usuario que solicita ya dio like (por defecto false).
   * @returns PostResponseDTO serializable.
   */
  toResponseDTO(entity: Post, authorName: string, authorPhoto?: string, isLikedByMe?: boolean): PostResponseDTO;
}
