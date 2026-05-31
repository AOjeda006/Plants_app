/**
 * @file DeleteCommentUseCase.ts
 * @description Caso de uso para eliminar un comentario propio.
 * Valida ownership, soft-delete y decrementa commentsCount del post padre.
 * @module Community
 * @layer Domain
 *
 * @injectable
 * @dependencies ICommentRepository, IPostRepository
 */

import { injectable, inject } from 'inversify';
import { TYPES } from '../../../core/types.js';
import type { ICommentRepository } from '../../repositories/ICommentRepository.js';
import type { IPostRepository } from '../../repositories/IPostRepository.js';
import type { IDeleteCommentUseCase } from '../../interfaces/usecases/community/IDeleteCommentUseCase.js';
import { NotFoundException } from '../../../core/exceptions/NotFoundException.js';
import { ForbiddenException } from '../../../core/exceptions/ForbiddenException.js';
import { createLogger } from '../../../core/logger.js';

const logger = createLogger('DeleteCommentUseCase');

/**
 * Elimina (soft-delete) un comentario propio del usuario.
 * Decrementa el contador commentsCount del post padre.
 *
 * @implements {IDeleteCommentUseCase}
 * @injectable
 * @dependencies ICommentRepository, IPostRepository
 */
@injectable()
export class DeleteCommentUseCase implements IDeleteCommentUseCase {
  constructor(
    @inject(TYPES.ICommentRepository) private readonly commentRepo: ICommentRepository,
    @inject(TYPES.IPostRepository)    private readonly postRepo: IPostRepository,
  ) {}

  /**
   * Ejecuta el caso de uso.
   *
   * @param commentId — Id del comentario a eliminar.
   * @param userId — Id del usuario solicitante (debe ser el autor).
   * @throws NotFoundException — Si el comentario no existe o ya fue eliminado.
   * @throws ForbiddenException — Si el usuario no es el autor del comentario.
   */
  async execute(commentId: string, userId: string): Promise<void> {
    const comment = await this.commentRepo.findById(commentId);
    if (!comment || comment.deletedAt !== null) {
      throw new NotFoundException(`Comentario ${commentId} no encontrado`);
    }

    // Validar ownership: solo el autor puede eliminar su propio comentario.
    if (comment.userId !== userId) {
      throw new ForbiddenException('No puedes eliminar un comentario que no es tuyo');
    }

    await this.commentRepo.softDelete(commentId);
    // Decrementar el contador de comentarios del post padre.
    await this.postRepo.incrementCommentsCount(comment.postId, -1);
    logger.info(`Usuario ${userId} eliminó su comentario ${commentId} del post ${comment.postId}`);
  }
}
