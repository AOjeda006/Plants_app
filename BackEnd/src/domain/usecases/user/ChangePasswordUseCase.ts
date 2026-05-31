/**
 * @file ChangePasswordUseCase.ts
 * @description Caso de uso para cambiar la contraseña del usuario autenticado.
 * Verifica la contraseña actual antes de aplicar el cambio.
 * @module User
 * @layer Domain
 *
 * @implements {IChangePasswordUseCase}
 * @injectable
 * @dependencies IUserRepository, HashService
 */

import { injectable, inject } from 'inversify';
import { TYPES } from '../../../core/types.js';
import type { IChangePasswordUseCase } from '../../interfaces/usecases/user/IChangePasswordUseCase.js';
import type { IUserRepository } from '../../repositories/IUserRepository.js';
import { HashService } from '../../../presentation/services/HashService.js';
import { NotFoundException } from '../../../core/exceptions/NotFoundException.js';
import { HttpException } from '../../../core/exceptions/HttpException.js';

/**
 * Cambia la contraseña del usuario tras verificar la contraseña actual.
 *
 * @implements {IChangePasswordUseCase}
 * @injectable
 * @dependencies IUserRepository, HashService
 */
@injectable()
export class ChangePasswordUseCase implements IChangePasswordUseCase {
  constructor(
    @inject(TYPES.IUserRepository) private readonly userRepo: IUserRepository,
    @inject(TYPES.HashService)     private readonly hashService: HashService,
  ) {}

  /**
   * @param userId — ID del usuario autenticado.
   * @param currentPassword — Contraseña actual en texto plano.
   * @param newPassword — Nueva contraseña en texto plano (mínimo 8 caracteres validados en DTO).
   * @returns void.
   * @throws {NotFoundException} Si el usuario no existe.
   * @throws {HttpException} 401 si la contraseña actual es incorrecta.
   */
  async execute(userId: string, currentPassword: string, newPassword: string): Promise<void> {
    const user = await this.userRepo.findById(userId);
    if (!user) throw new NotFoundException('User', userId);

    const isMatch = await this.hashService.compare(currentPassword, user.passwordHash);
    if (!isMatch) {
      throw new HttpException('Contraseña actual incorrecta', 401, 'INVALID_CREDENTIALS');
    }

    const newHash = await this.hashService.hash(newPassword);
    await this.userRepo.update(userId, { passwordHash: newHash });
  }
}
