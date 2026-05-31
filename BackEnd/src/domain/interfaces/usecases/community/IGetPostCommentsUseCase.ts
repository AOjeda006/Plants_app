/**
 * @file IGetPostCommentsUseCase.ts
 * @description Interfaz del caso de uso para obtener comentarios de un post.
 * @module Community
 * @layer Domain
 */

import type { CommentResponseDTO } from '../../../dtos/community/comment-response.dto.js';

/**
 * Contrato del use case GetPostComments.
 */
export interface IGetPostCommentsUseCase {
  /**
   * Ejecuta el caso de uso.
   *
   * @param postId — Id del post cuyos comentarios se solicitan.
   * @returns Lista de CommentResponseDTOs ordenada por fecha ascendente.
   */
  execute(postId: string): Promise<CommentResponseDTO[]>;
}
