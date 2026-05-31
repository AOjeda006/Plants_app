/**
 * @file IGetFeedUseCase.ts
 * @description Interfaz del caso de uso para obtener el feed de la comunidad.
 * @module Community
 * @layer Domain
 */

import type { PostResponseDTO } from '../../../dtos/community/post-response.dto.js';

/**
 * Contrato del use case GetFeed.
 * Devuelve el feed global paginado de posts con datos del autor embebidos.
 */
export interface IGetFeedUseCase {
  /**
   * Ejecuta el caso de uso.
   *
   * @param userId   — Id del usuario que solicita (para isLikedByMe y exclusión de propios).
   * @param page     — Número de página (base 1). Por defecto 1.
   * @param limit    — Elementos por página. Por defecto 20.
   * @param authorId — Si se proporciona, devuelve SOLO los posts de ese autor (perfil propio).
   *                   Si no se proporciona, es el feed de comunidad (excluye los propios).
   * @returns Lista paginada de PostResponseDTOs.
   */
  execute(userId: string, page?: number, limit?: number, authorId?: string): Promise<PostResponseDTO[]>;
}
