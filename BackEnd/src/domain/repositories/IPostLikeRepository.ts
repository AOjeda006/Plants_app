/**
 * @file IPostLikeRepository.ts
 * @description Interfaz del repositorio de likes de posts. Define el contrato de
 * acceso a datos sin acoplar la capa de dominio a ninguna implementación concreta.
 * @module Community
 * @layer Domain
 */

import type { ClientSession } from 'mongodb';
import type { PostLike } from '../entities/PostLike.js';

/**
 * Contrato del repositorio de likes de posts.
 * La unicidad (postId + userId) se garantiza mediante índice único en MongoDB.
 */
export interface IPostLikeRepository {
  /**
   * Busca el like de un usuario concreto en un post concreto.
   *
   * @param postId — Id del post.
   * @param userId — Id del usuario.
   * @returns PostLike encontrado o null.
   */
  findByPostAndUser(postId: string, userId: string): Promise<PostLike | null>;

  /**
   * Registra un nuevo like.
   *
   * @param postId — Id del post.
   * @param userId — Id del usuario que da like.
   * @param session — Sesión de transacción opcional.
   * @returns PostLike creado.
   */
  create(postId: string, userId: string, session?: ClientSession): Promise<PostLike>;

  /**
   * Elimina el like de un usuario en un post (borrado físico).
   *
   * @param postId — Id del post.
   * @param userId — Id del usuario.
   * @param session — Sesión de transacción opcional.
   */
  delete(postId: string, userId: string, session?: ClientSession): Promise<void>;
}
