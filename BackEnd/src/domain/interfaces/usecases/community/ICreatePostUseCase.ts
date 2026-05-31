/**
 * @file ICreatePostUseCase.ts
 * @description Interfaz del caso de uso para crear un post en la comunidad.
 * @module Community
 * @layer Domain
 */

import type { CreatePostRequestDto } from '../../../dtos/community/create-post-request.dto.js';
import type { PostResponseDTO } from '../../../dtos/community/post-response.dto.js';

/**
 * Contrato del use case CreatePost.
 */
export interface ICreatePostUseCase {
  /**
   * Ejecuta el caso de uso.
   *
   * @param authorId — Id del usuario que crea el post.
   * @param data — Datos del post a crear.
   * @returns PostResponseDTO del post creado.
   */
  execute(authorId: string, data: CreatePostRequestDto): Promise<PostResponseDTO>;
}
