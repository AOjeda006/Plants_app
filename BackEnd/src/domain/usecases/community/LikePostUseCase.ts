/**
 * @file LikePostUseCase.ts
 * @description Caso de uso para dar like a un post.
 * Lanza 409 Conflict si el usuario ya había dado like (no idempotente).
 * El frontend usa isLikedByMe del feed para mostrar el toggle correcto.
 * @module Community
 * @layer Domain
 *
 * @implements {ILikePostUseCase}
 * @injectable
 * @dependencies IPostRepository, IPostLikeRepository
 */

import { injectable, inject } from 'inversify';
import { TYPES } from '../../../core/types.js';
import type { ILikePostUseCase } from '../../interfaces/usecases/community/ILikePostUseCase.js';
import type { IPostRepository } from '../../repositories/IPostRepository.js';
import type { IPostLikeRepository } from '../../repositories/IPostLikeRepository.js';
import { NotFoundException } from '../../../core/exceptions/NotFoundException.js';
import { ConflictException } from '../../../core/exceptions/ConflictException.js';

/**
 * Registra el like de un usuario en un post y actualiza el contador del post.
 * Si el like ya existía, lanza ConflictException (409) para que el frontend
 * pueda detectar un doble-tap y revertir el estado optimista.
 *
 * @implements {ILikePostUseCase}
 * @injectable
 * @dependencies IPostRepository, IPostLikeRepository
 */
@injectable()
export class LikePostUseCase implements ILikePostUseCase {
  constructor(
    @inject(TYPES.IPostRepository)     private readonly postRepo: IPostRepository,
    @inject(TYPES.IPostLikeRepository) private readonly likeRepo: IPostLikeRepository,
  ) {}

  /**
   * @param postId — Id del post al que se da like.
   * @param userId — Id del usuario que da like.
   * @throws {NotFoundException}  Si el post no existe o está eliminado.
   * @throws {ConflictException}  Si el usuario ya había dado like a este post.
   */
  async execute(postId: string, userId: string): Promise<void> {
    const post = await this.postRepo.findById(postId);
    if (!post) throw new NotFoundException('Post', postId);

    const existing = await this.likeRepo.findByPostAndUser(postId, userId);
    if (existing) throw new ConflictException('Ya has dado like a este post.', 'LIKE_ALREADY_EXISTS');

    await this.likeRepo.create(postId, userId);
    await this.postRepo.incrementLikesCount(postId, 1);
  }
}
