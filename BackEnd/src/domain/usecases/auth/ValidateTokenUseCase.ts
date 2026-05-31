/**
 * @file ValidateTokenUseCase.ts
 * @description Caso de uso de validación de token JWT.
 * Decodifica el token, verifica que el usuario existe y devuelve sus datos públicos.
 * @module Auth
 * @layer Domain
 *
 * @implements {IValidateTokenUseCase}
 * @injectable
 * @dependencies JwtService, IUserRepository
 */

import { injectable, inject } from 'inversify';
import type { IValidateTokenUseCase } from '../../interfaces/usecases/auth/IValidateTokenUseCase.js';
import type { IUserRepository } from '../../repositories/IUserRepository.js';
import type { UserResponseDTO } from '../../dtos/user/user-response.dto.js';
import { JwtService } from '../../../presentation/services/JwtService.js';
import { TYPES } from '../../../core/types.js';
import { NotFoundException } from '../../../core/exceptions/NotFoundException.js';

/**
 * Valida un token JWT y devuelve los datos públicos del usuario asociado.
 *
 * @implements {IValidateTokenUseCase}
 * @injectable
 * @dependencies JwtService, IUserRepository
 */
@injectable()
export class ValidateTokenUseCase implements IValidateTokenUseCase {
  constructor(
    @inject(TYPES.JwtService)      private readonly jwtService: JwtService,
    @inject(TYPES.IUserRepository) private readonly userRepo: IUserRepository,
  ) {}

  /**
   * Verifica el token JWT y devuelve los datos públicos del usuario.
   *
   * @param token — Token JWT a validar.
   * @returns Datos públicos del usuario si el token es válido.
   * @throws {UnauthorizedException} Si el token es inválido o ha expirado.
   * @throws {NotFoundException} Si el usuario del token ya no existe.
   */
  async execute(token: string): Promise<UserResponseDTO> {
    const payload = this.jwtService.verify(token);

    const user = await this.userRepo.findById(payload.userId);
    if (!user) {
      throw new NotFoundException('User', payload.userId);
    }

    return user.sanitizeForPublic();
  }
}
