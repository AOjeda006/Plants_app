/**
 * @file CreateCommentUseCase.ts
 * @description Caso de uso para crear un comentario en un post.
 * Incrementa atómicamente el contador de comentarios del post.
 * @module Community
 * @layer Domain
 *
 * @implements {ICreateCommentUseCase}
 * @injectable
 * @dependencies ICommentRepository, IPostRepository, IUserRepository, ICommentMapper
 */

import { injectable, inject } from 'inversify';
import { TYPES } from '../../../core/types.js';
import type { ICreateCommentUseCase } from '../../interfaces/usecases/community/ICreateCommentUseCase.js';
import type { ICommentRepository } from '../../repositories/ICommentRepository.js';
import type { IPostRepository } from '../../repositories/IPostRepository.js';
import type { IUserRepository } from '../../repositories/IUserRepository.js';
import type { ICommentMapper } from '../../../data/IMappers/ICommentMapper.js';
import type { CommentResponseDTO } from '../../dtos/community/comment-response.dto.js';
import { NotFoundException } from '../../../core/exceptions/NotFoundException.js';

/**
 * Crea un comentario en un post y actualiza el contador de comentarios del post.
 *
 * @implements {ICreateCommentUseCase}
 * @injectable
 * @dependencies ICommentRepository, IPostRepository, IUserRepository, ICommentMapper
 */
@injectable()
export class CreateCommentUseCase implements ICreateCommentUseCase {
  constructor(
    @inject(TYPES.ICommentRepository) private readonly commentRepo: ICommentRepository,
    @inject(TYPES.IPostRepository)    private readonly postRepo: IPostRepository,
    @inject(TYPES.IUserRepository)    private readonly userRepo: IUserRepository,
    @inject(TYPES.ICommentMapper)     private readonly mapper: ICommentMapper,
  ) {}

  /**
   * @param postId — Id del post en el que se comenta.
   * @param authorId — Id del usuario que escribe el comentario.
   * @param content — Texto del comentario (máx. 500 chars).
   * @returns CommentResponseDTO del comentario creado.
   * @throws {NotFoundException} Si el post o el usuario no existen.
   */
  async execute(postId: string, authorId: string, content: string): Promise<CommentResponseDTO> {
    const post = await this.postRepo.findById(postId);
    if (!post) throw new NotFoundException('Post', postId);

    const author = await this.userRepo.findById(authorId);
    if (!author) throw new NotFoundException('User', authorId);

    const comment = await this.commentRepo.create(postId, authorId, content);
    await this.postRepo.incrementCommentsCount(postId, 1);

    return this.mapper.toResponseDTO(comment, author.name, author.photo);
  }
}
