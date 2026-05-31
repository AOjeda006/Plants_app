/**
 * @file GetFeedUseCase.ts
 * @description Caso de uso para obtener el feed global paginado de la comunidad.
 * Enriquece cada post con datos del autor e indicador isLikedByMe (N+1 — TFG).
 * @module Community
 * @layer Domain
 *
 * @implements {IGetFeedUseCase}
 * @injectable
 * @dependencies IPostRepository, IUserRepository, IPostLikeRepository, IPostMapper
 */

import { injectable, inject } from 'inversify';
import { TYPES } from '../../../core/types.js';
import type { IGetFeedUseCase } from '../../interfaces/usecases/community/IGetFeedUseCase.js';
import type { IPostRepository } from '../../repositories/IPostRepository.js';
import type { IUserRepository } from '../../repositories/IUserRepository.js';
import type { IPostLikeRepository } from '../../repositories/IPostLikeRepository.js';
import type { IPostMapper } from '../../../data/IMappers/IPostMapper.js';
import type { PostResponseDTO } from '../../dtos/community/post-response.dto.js';

/**
 * Obtiene el feed global de posts paginado, enriquecido con datos de autor e isLikedByMe.
 *
 * @implements {IGetFeedUseCase}
 * @injectable
 * @dependencies IPostRepository, IUserRepository, IPostLikeRepository, IPostMapper
 */
@injectable()
export class GetFeedUseCase implements IGetFeedUseCase {
  constructor(
    @inject(TYPES.IPostRepository)     private readonly postRepo: IPostRepository,
    @inject(TYPES.IUserRepository)     private readonly userRepo: IUserRepository,
    @inject(TYPES.IPostLikeRepository) private readonly likeRepo: IPostLikeRepository,
    @inject(TYPES.IPostMapper)         private readonly mapper: IPostMapper,
  ) {}

  /**
   * @param userId   — Id del usuario solicitante. Se usa para calcular isLikedByMe.
   * @param page     — Página (base 1). Por defecto 1.
   * @param limit    — Elementos por página. Por defecto 20.
   * @param authorId — Si se proporciona, devuelve SOLO los posts de ese autor (modo perfil).
   *                   Si no, es el feed de comunidad (excluye posts propios del userId).
   * @returns Lista paginada de PostResponseDTOs con isLikedByMe.
   */
  async execute(userId: string, page = 1, limit = 20, authorId?: string): Promise<PostResponseDTO[]> {
    const posts = await this.postRepo.findFeed(page, limit);

    // Consultar rol del solicitante: los admins ven posts de usuarios privados (moderación).
    const requestingUser = await this.userRepo.findById(userId);
    const isAdmin = requestingUser?.role === 'admin';

    // TFG: N+1 aceptable para datasets pequeños. En producción usar $lookup o caché de usuarios.
    const result: PostResponseDTO[] = [];
    for (const post of posts) {
      if (authorId) {
        // Modo perfil: solo posts del autor indicado.
        if (post.userId !== authorId) continue;
      } else {
        // Modo feed de comunidad: excluir los posts propios del solicitante.
        if (post.userId === userId) continue;
      }

      const [author, like] = await Promise.all([
        this.userRepo.findById(post.userId),
        this.likeRepo.findByPostAndUser(post.id, userId),
      ]);

      // En modo feed de comunidad: excluir posts de usuarios eliminados.
      // Con preserveContent=true el post tiene deletedAt:null pero su autor ya no existe.
      // Estos posts siguen siendo accesibles vía página de perfil (modo authorId).
      if (!authorId && author === null) continue;

      // Excluir posts de usuarios con perfil privado, salvo que sea el propio usuario o admin.
      if (author?.preferences?.isPrivate && post.userId !== userId && !isAdmin) continue;

      result.push(this.mapper.toResponseDTO(
        post,
        author?.name ?? 'Usuario eliminado',
        author?.photo,
        like !== null,
      ));
    }

    return result;
  }
}
