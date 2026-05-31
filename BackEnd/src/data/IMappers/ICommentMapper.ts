/**
 * @file ICommentMapper.ts
 * @description Interfaz del mapper de comentarios de posts.
 * Define el contrato de transformación entre documento MongoDB, entidad de dominio y DTO de respuesta.
 * @module Community
 * @layer Data
 */

import type { Comment } from '../../domain/entities/Comment.js';
import type { CommentDocument } from '../datasources/mongodb/models/CommentModel.js';
import type { CommentResponseDTO } from '../../domain/dtos/community/comment-response.dto.js';

/**
 * Contrato del mapper de comentarios.
 * Los repositorios dependen de esta interfaz, no de la implementación concreta.
 */
export interface ICommentMapper {
  /**
   * Convierte un documento MongoDB a entidad Comment de dominio.
   *
   * @param doc — Documento de la colección 'comments'.
   * @returns Entidad Comment.
   */
  toEntity(doc: CommentDocument): Comment;

  /**
   * Convierte datos crudos a documento MongoDB (sin _id).
   *
   * @param postId — Id del post como ObjectId string.
   * @param userId — Id del usuario como ObjectId string.
   * @param content — Texto del comentario.
   * @returns Documento parcial para insertar en MongoDB.
   */
  toDocument(postId: string, userId: string, content: string): Omit<CommentDocument, '_id'>;

  /**
   * Convierte una entidad Comment al DTO de respuesta HTTP, enriquecido con datos del autor.
   *
   * @param entity — Entidad Comment.
   * @param authorName — Nombre del autor del comentario.
   * @param authorPhoto — URL de la foto del autor (opcional).
   * @returns CommentResponseDTO serializable.
   */
  toResponseDTO(entity: Comment, authorName: string, authorPhoto?: string): CommentResponseDTO;
}
