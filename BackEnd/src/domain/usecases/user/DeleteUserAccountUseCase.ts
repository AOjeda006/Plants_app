/**
 * @file DeleteUserAccountUseCase.ts
 * @description Caso de uso para eliminar la cuenta del usuario (soft-delete).
 * Requiere confirmación de contraseña para ejecutarse.
 * Soporta modo preserveContent: si true, las publicaciones y comentarios del usuario
 * permanecen en la BD (anónimos); si false, se eliminan junto con la cuenta.
 * @module User
 * @layer Domain
 *
 * @implements {IDeleteUserAccountUseCase}
 * @injectable
 * @dependencies IUserRepository, HashService, IPostRepository, ICommentRepository
 */

import { injectable, inject } from 'inversify';
import { TYPES } from '../../../core/types.js';
import type { IDeleteUserAccountUseCase } from '../../interfaces/usecases/user/IDeleteUserAccountUseCase.js';
import type { IUserRepository } from '../../repositories/IUserRepository.js';
import type { IPostRepository } from '../../repositories/IPostRepository.js';
import type { ICommentRepository } from '../../repositories/ICommentRepository.js';
import { HashService } from '../../../presentation/services/HashService.js';
import { NotFoundException } from '../../../core/exceptions/NotFoundException.js';
import { HttpException } from '../../../core/exceptions/HttpException.js';

/**
 * Realiza el borrado lógico (soft-delete) de la cuenta del usuario.
 * Requiere verificación de contraseña como segundo factor de confirmación.
 *
 * @implements {IDeleteUserAccountUseCase}
 * @injectable
 * @dependencies IUserRepository, HashService, IPostRepository, ICommentRepository
 */
@injectable()
export class DeleteUserAccountUseCase implements IDeleteUserAccountUseCase {
  constructor(
    @inject(TYPES.IUserRepository)     private readonly userRepo:    IUserRepository,
    @inject(TYPES.HashService)         private readonly hashService: HashService,
    @inject(TYPES.IPostRepository)     private readonly postRepo:    IPostRepository,
    @inject(TYPES.ICommentRepository)  private readonly commentRepo: ICommentRepository,
  ) {}

  /**
   * @param userId          — ID del usuario autenticado.
   * @param password        — Contraseña actual para confirmar la eliminación.
   * @param preserveContent — Si false (default): soft-delete posts y comentarios.
   *                          Si true: se mantienen (el usuario ya no estará visible).
   * @returns void.
   * @throws {NotFoundException} Si el usuario no existe.
   * @throws {HttpException} 401 si la contraseña es incorrecta.
   */
  async execute(userId: string, password: string, preserveContent = false): Promise<void> {
    const user = await this.userRepo.findById(userId);
    if (!user) throw new NotFoundException('User', userId);

    const isMatch = await this.hashService.compare(password, user.passwordHash);
    if (!isMatch) {
      throw new HttpException('Contraseña incorrecta', 401, 'INVALID_CREDENTIALS');
    }

    if (!preserveContent) {
      // Decrementar commentsCount de los posts afectados antes de borrar los comentarios.
      // Se decrementa -1 por cada comentario activo del usuario.
      const userComments = await this.commentRepo.findActiveByUserId(userId);
      await Promise.all(
        userComments.map(comment => this.postRepo.incrementCommentsCount(comment.postId, -1)),
      );

      // Eliminar publicaciones y comentarios del usuario.
      await this.postRepo.softDeleteByUserId(userId);
      await this.commentRepo.softDeleteByUserId(userId);
    }
    // TFG: si preserveContent=true, los posts/comments quedan activos. El autor
    // dejará de ser resoluble (usuario soft-deleted), apareciendo como anónimo.

    // Soft-delete: establece deletedAt en el documento, el usuario deja de ser visible.
    await this.userRepo.delete(userId, true);
  }
}
