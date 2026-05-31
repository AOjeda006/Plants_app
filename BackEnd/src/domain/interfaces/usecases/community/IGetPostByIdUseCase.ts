/**
 * @file IGetPostByIdUseCase.ts
 * @description Interfaz del caso de uso para obtener un post por ID.
 * @module Community
 * @layer Domain
 */

import type { PostResponseDTO } from '../../../dtos/community/post-response.dto.js';

/**
 * Contrato del use case GetPostById.
 * Devuelve un post enriquecido con datos del autor.
 */
export interface IGetPostByIdUseCase {
  /**
   * Ejecuta el caso de uso.
   *
   * @param postId           — Id del post a obtener.
   * @param requestingUserId — Id del usuario que solicita (para calcular isLikedByMe).
   * @returns PostResponseDTO con isLikedByMe correcto.
   * @throws {NotFoundException} Si el post no existe o está eliminado.
   */
  execute(postId: string, requestingUserId?: string): Promise<PostResponseDTO>;
}
