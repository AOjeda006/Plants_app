/**
 * @file CreatePostUseCase.ts
 * @description Caso de uso para crear un nuevo post en la comunidad.
 * @module Community
 * @layer Domain
 *
 * @implements {ICreatePostUseCase}
 * @injectable
 * @dependencies IPostRepository, IUserRepository, IPostMapper
 */

import { injectable, inject } from 'inversify';
import { TYPES } from '../../../core/types.js';
import type { ICreatePostUseCase } from '../../interfaces/usecases/community/ICreatePostUseCase.js';
import type { IPostRepository } from '../../repositories/IPostRepository.js';
import type { IUserRepository } from '../../repositories/IUserRepository.js';
import type { IPostMapper } from '../../../data/IMappers/IPostMapper.js';
import type { CreatePostRequestDto } from '../../dtos/community/create-post-request.dto.js';
import type { PostResponseDTO } from '../../dtos/community/post-response.dto.js';
import { NotFoundException } from '../../../core/exceptions/NotFoundException.js';

/**
 * Crea un nuevo post para el usuario autenticado.
 *
 * @implements {ICreatePostUseCase}
 * @injectable
 * @dependencies IPostRepository, IUserRepository, IPostMapper
 */
@injectable()
export class CreatePostUseCase implements ICreatePostUseCase {
  constructor(
    @inject(TYPES.IPostRepository) private readonly postRepo: IPostRepository,
    @inject(TYPES.IUserRepository) private readonly userRepo: IUserRepository,
    @inject(TYPES.IPostMapper)     private readonly mapper: IPostMapper,
  ) {}

  /**
   * @param authorId — Id del usuario que crea el post.
   * @param data — Datos del post validados.
   * @returns PostResponseDTO del post creado.
   * @throws {NotFoundException} Si el usuario no existe.
   */
  async execute(authorId: string, data: CreatePostRequestDto): Promise<PostResponseDTO> {
    const author = await this.userRepo.findById(authorId);
    if (!author) throw new NotFoundException('User', authorId);

    const post = await this.postRepo.create({
      userId:        authorId,
      content:       data.content,
      image:         data.imageUrl,
      likesCount:    0,
      commentsCount: 0,
      seenBy:        [],
      createdAt:     new Date(),
      updatedAt:     new Date(),
      deletedAt:     null,
    });

    return this.mapper.toResponseDTO(post, author.name, author.photo);
  }
}
