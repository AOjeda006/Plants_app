/**
 * @file GetPostByIdUseCase.ts
 * @description Caso de uso para obtener un post concreto por su ID, con datos del autor.
 * @module Community
 * @layer Domain
 *
 * @implements {IGetPostByIdUseCase}
 * @injectable
 * @dependencies IPostRepository, IUserRepository, IPostLikeRepository, IPostMapper
 */

import { injectable, inject } from 'inversify';
import { TYPES } from '../../../core/types.js';
import type { IGetPostByIdUseCase } from '../../interfaces/usecases/community/IGetPostByIdUseCase.js';
import type { IPostRepository } from '../../repositories/IPostRepository.js';
import type { IUserRepository } from '../../repositories/IUserRepository.js';
import type { IPostLikeRepository } from '../../repositories/IPostLikeRepository.js';
import type { IPostMapper } from '../../../data/IMappers/IPostMapper.js';
import type { PostResponseDTO } from '../../dtos/community/post-response.dto.js';
import { NotFoundException } from '../../../core/exceptions/NotFoundException.js';

/**
 * Obtiene un post por su ID, enriquecido con datos del autor e isLikedByMe.
 *
 * @implements {IGetPostByIdUseCase}
 * @injectable
 * @dependencies IPostRepository, IUserRepository, IPostLikeRepository, IPostMapper
 */
@injectable()
export class GetPostByIdUseCase implements IGetPostByIdUseCase {
  constructor(
    @inject(TYPES.IPostRepository)     private readonly postRepo: IPostRepository,
    @inject(TYPES.IUserRepository)     private readonly userRepo: IUserRepository,
    @inject(TYPES.IPostLikeRepository) private readonly likeRepo: IPostLikeRepository,
    @inject(TYPES.IPostMapper)         private readonly mapper: IPostMapper,
  ) {}

  /**
   * @param postId           — Id del post a obtener.
   * @param requestingUserId — Id del usuario que solicita (para calcular isLikedByMe).
   * @returns PostResponseDTO con datos del autor e isLikedByMe correcto.
   * @throws {NotFoundException} Si el post no existe o está eliminado.
   */
  async execute(postId: string, requestingUserId?: string): Promise<PostResponseDTO> {
    const post = await this.postRepo.findById(postId);
    if (!post) throw new NotFoundException('Post', postId);

    const [author, like] = await Promise.all([
      this.userRepo.findById(post.userId),
      requestingUserId
        ? this.likeRepo.findByPostAndUser(postId, requestingUserId)
        : Promise.resolve(null),
    ]);

    return this.mapper.toResponseDTO(
      post,
      author?.name ?? 'Usuario eliminado',
      author?.photo,
      like !== null,
    );
  }
}
