/**
 * @file ICommentRepository.ts
 * @description Interfaz del repositorio de comentarios de posts. Define el contrato de
 * acceso a datos sin acoplar la capa de dominio a ninguna implementación concreta.
 * @module Community
 * @layer Domain
 */

import type { ClientSession } from 'mongodb';
import type { Comment } from '../entities/Comment.js';

/**
 * Contrato del repositorio de comentarios.
 * Los use cases dependen de esta interfaz, nunca de la implementación concreta.
 */
export interface ICommentRepository {
  /**
   * Obtiene los comentarios activos de un post, ordenados por fecha ascendente.
   *
   * @param postId — Id del post.
   * @returns Lista de comentarios del post.
   */
  findByPostId(postId: string): Promise<Comment[]>;

  /**
   * Busca un comentario por su id (incluye borrados lógicamente).
   *
   * @param id — Id del comentario.
   * @returns Comentario encontrado o null.
   */
  findById(id: string): Promise<Comment | null>;

  /**
   * Crea un nuevo comentario en la base de datos.
   *
   * @param postId — Id del post comentado.
   * @param userId — Id del autor del comentario.
   * @param content — Texto del comentario.
   * @param session — Sesión de transacción opcional.
   * @returns Comentario creado con id asignado.
   */
  create(
    postId: string,
    userId: string,
    content: string,
    session?: ClientSession,
  ): Promise<Comment>;

  /**
   * Obtiene todos los comentarios activos de un usuario.
   * Usado para decrementar commentsCount en los posts afectados antes de borrar.
   *
   * @param userId — ID del usuario.
   * @returns Lista de comentarios activos del usuario.
   */
  findActiveByUserId(userId: string): Promise<Comment[]>;

  /**
   * Soft-delete de un comentario individual.
   * Marca deletedAt con la fecha actual.
   *
   * @param id — ID del comentario a eliminar.
   */
  softDelete(id: string): Promise<void>;

  /**
   * Soft-delete masivo de todos los comentarios activos de un usuario.
   * Usado al eliminar la cuenta con preserveContent=false.
   *
   * @param userId — ID del usuario cuyos comentarios se eliminan.
   */
  softDeleteByUserId(userId: string): Promise<void>;
}
