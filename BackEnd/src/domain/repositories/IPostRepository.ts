/**
 * @file IPostRepository.ts
 * @description Interfaz del repositorio de posts de la comunidad. Define el contrato de
 * acceso a datos sin acoplar la capa de dominio a ninguna implementación concreta.
 * @module Community
 * @layer Domain
 */

import type { ClientSession } from 'mongodb';
import type { Post } from '../entities/Post.js';

/**
 * Contrato del repositorio de posts.
 * Los use cases dependen de esta interfaz, nunca de la implementación concreta.
 */
export interface IPostRepository {
  /**
   * Obtiene el feed global de posts activos, ordenado por fecha descendente.
   *
   * @param page — Número de página (base 1).
   * @param limit — Elementos por página.
   * @returns Lista paginada de posts.
   */
  findFeed(page: number, limit: number): Promise<Post[]>;

  /**
   * Busca un post activo por su id.
   *
   * @param id — Id del post.
   * @returns Post encontrado o null.
   */
  findById(id: string): Promise<Post | null>;

  /**
   * Crea un nuevo post en la base de datos.
   *
   * @param post — Datos del post sin id.
   * @param session — Sesión de transacción opcional.
   * @returns Post creado con id asignado.
   */
  create(post: Omit<Post, 'id' | 'isActive'>, session?: ClientSession): Promise<Post>;

  /**
   * Incrementa o decrementa el contador de likes de un post de forma atómica.
   *
   * @param id — Id del post.
   * @param delta — +1 para like, -1 para unlike.
   * @param session — Sesión de transacción opcional.
   */
  incrementLikesCount(id: string, delta: 1 | -1, session?: ClientSession): Promise<void>;

  /**
   * Incrementa o decrementa el contador de comentarios de un post de forma atómica.
   *
   * @param id — Id del post.
   * @param delta — +1 al añadir, -1 al borrar.
   * @param session — Sesión de transacción opcional.
   */
  incrementCommentsCount(id: string, delta: 1 | -1, session?: ClientSession): Promise<void>;

  /**
   * Soft-delete de un post individual.
   * Marca deletedAt con la fecha actual.
   *
   * @param id — ID del post a eliminar.
   */
  softDelete(id: string): Promise<void>;

  /**
   * Soft-delete masivo de todos los posts activos de un usuario.
   * Usado al eliminar la cuenta con preserveContent=false.
   *
   * @param userId — ID del usuario cuyos posts se eliminan.
   */
  softDeleteByUserId(userId: string): Promise<void>;
}
