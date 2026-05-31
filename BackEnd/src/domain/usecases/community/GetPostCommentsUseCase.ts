/**
 * @file GetPostCommentsUseCase.ts
 * @description Caso de uso para obtener los comentarios activos de un post.
 * Enriquece cada comentario con los datos del autor (N+1 — aceptable para TFG).
 * @module Community
 * @layer Domain
 *
 * @implements {IGetPostCommentsUseCase}
 * @injectable
 * @dependencies ICommentRepository, IUserRepository, ICommentMapper
 */

import { injectable, inject } from 'inversify';
import { TYPES } from '../../../core/types.js';
import type { IGetPostCommentsUseCase } from '../../interfaces/usecases/community/IGetPostCommentsUseCase.js';
import type { ICommentRepository } from '../../repositories/ICommentRepository.js';
import type { IUserRepository } from '../../repositories/IUserRepository.js';
import type { ICommentMapper } from '../../../data/IMappers/ICommentMapper.js';
import type { CommentResponseDTO } from '../../dtos/community/comment-response.dto.js';

/**
 * Obtiene los comentarios activos de un post, enriquecidos con datos del autor.
 *
 * @implements {IGetPostCommentsUseCase}
 * @injectable
 * @dependencies ICommentRepository, IUserRepository, ICommentMapper
 */
@injectable()
export class GetPostCommentsUseCase implements IGetPostCommentsUseCase {
  constructor(
    @inject(TYPES.ICommentRepository) private readonly commentRepo: ICommentRepository,
    @inject(TYPES.IUserRepository)    private readonly userRepo: IUserRepository,
    @inject(TYPES.ICommentMapper)     private readonly mapper: ICommentMapper,
  ) {}

  /**
   * @param postId — Id del post cuyos comentarios se solicitan.
   * @returns Lista de CommentResponseDTOs ordenada cronológicamente.
   */
  async execute(postId: string): Promise<CommentResponseDTO[]> {
    const comments = await this.commentRepo.findByPostId(postId);

    // TFG: N+1 aceptable para datasets pequeños. En producción usar $lookup.
    const result: CommentResponseDTO[] = [];
    for (const comment of comments) {
      const author = await this.userRepo.findById(comment.userId);
      result.push(this.mapper.toResponseDTO(
        comment,
        author?.name ?? 'Usuario eliminado',
        author?.photo,
      ));
    }

    return result;
  }
}
