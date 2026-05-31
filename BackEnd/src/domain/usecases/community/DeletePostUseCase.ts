/**
 * @file DeletePostUseCase.ts
 * @description Caso de uso para eliminar un post propio.
 * Valida que el usuario sea el autor del post antes de hacer soft-delete.
 * @module Community
 * @layer Domain
 *
 * @injectable
 * @dependencies IPostRepository
 */

import { injectable, inject } from 'inversify';
import { TYPES } from '../../../core/types.js';
import type { IPostRepository } from '../../repositories/IPostRepository.js';
import type { IDeletePostUseCase } from '../../interfaces/usecases/community/IDeletePostUseCase.js';
import { NotFoundException } from '../../../core/exceptions/NotFoundException.js';
import { ForbiddenException } from '../../../core/exceptions/ForbiddenException.js';
import { createLogger } from '../../../core/logger.js';

const logger = createLogger('DeletePostUseCase');

/**
 * Elimina (soft-delete) un post propio del usuario.
 *
 * @implements {IDeletePostUseCase}
 * @injectable
 * @dependencies IPostRepository
 */
@injectable()
export class DeletePostUseCase implements IDeletePostUseCase {
  constructor(
    @inject(TYPES.IPostRepository) private readonly postRepo: IPostRepository,
  ) {}

  /**
   * Ejecuta el caso de uso.
   *
   * @param postId — Id del post a eliminar.
   * @param userId — Id del usuario solicitante (debe ser el autor).
   * @throws NotFoundException — Si el post no existe o ya fue eliminado.
   * @throws ForbiddenException — Si el usuario no es el autor del post.
   */
  async execute(postId: string, userId: string): Promise<void> {
    const post = await this.postRepo.findById(postId);
    if (!post) {
      throw new NotFoundException(`Post ${postId} no encontrado`);
    }

    // Validar ownership: solo el autor puede eliminar su propio post.
    if (post.userId !== userId) {
      throw new ForbiddenException('No puedes eliminar un post que no es tuyo');
    }

    await this.postRepo.softDelete(postId);
    logger.info(`Usuario ${userId} eliminó su post ${postId}`);
  }
}
