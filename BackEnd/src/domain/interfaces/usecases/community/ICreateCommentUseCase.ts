/**
 * @file ICreateCommentUseCase.ts
 * @description Interfaz del caso de uso para crear un comentario en un post.
 * @module Community
 * @layer Domain
 */

import type { CommentResponseDTO } from '../../../dtos/community/comment-response.dto.js';

/**
 * Contrato del use case CreateComment (alias: AddComment en types.ts).
 */
export interface ICreateCommentUseCase {
  /**
   * Ejecuta el caso de uso.
   *
   * @param postId — Id del post en el que se comenta.
   * @param authorId — Id del usuario que escribe el comentario.
   * @param content — Texto del comentario (máx. 500 chars).
   * @returns CommentResponseDTO del comentario creado.
   * @throws {NotFoundException} Si el post no existe o está eliminado.
   */
  execute(postId: string, authorId: string, content: string): Promise<CommentResponseDTO>;
}
