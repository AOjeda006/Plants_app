/**
 * @file UnlikePostUseCase.ts
 * @description Caso de uso para quitar el like de un post.
 * Es idempotente: si el like no existe, no hace nada ni lanza error.
 * @module Community
 * @layer Domain
 *
 * @implements {IUnlikePostUseCase}
 * @injectable
 * @dependencies IPostRepository, IPostLikeRepository
 */

import { injectable, inject } from 'inversify';
import { TYPES } from '../../../core/types.js';
import type { IUnlikePostUseCase } from '../../interfaces/usecases/community/IUnlikePostUseCase.js';
import type { IPostRepository } from '../../repositories/IPostRepository.js';
import type { IPostLikeRepository } from '../../repositories/IPostLikeRepository.js';
import { NotFoundException } from '../../../core/exceptions/NotFoundException.js';

/**
 * Elimina el like de un usuario en un post y actualiza el contador del post.
 * Si el like no existía, la operación es un no-op (idempotente).
 *
 * @implements {IUnlikePostUseCase}
 * @injectable
 * @dependencies IPostRepository, IPostLikeRepository
 */
@injectable()
export class UnlikePostUseCase implements IUnlikePostUseCase {
  constructor(
    @inject(TYPES.IPostRepository)     private readonly postRepo: IPostRepository,
    @inject(TYPES.IPostLikeRepository) private readonly likeRepo: IPostLikeRepository,
  ) {}

  /**
   * @param postId — Id del post al que se quita el like.
   * @param userId — Id del usuario que retira su like.
   * @throws {NotFoundException} Si el post no existe o está eliminado.
   */
  async execute(postId: string, userId: string): Promise<void> {
    const post = await this.postRepo.findById(postId);
    if (!post) throw new NotFoundException('Post', postId);

    const existing = await this.likeRepo.findByPostAndUser(postId, userId);
    if (!existing) return;

    await this.likeRepo.delete(postId, userId);
    await this.postRepo.incrementLikesCount(postId, -1);
  }
}
