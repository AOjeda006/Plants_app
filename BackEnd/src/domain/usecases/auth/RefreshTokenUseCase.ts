/**
 * @file RefreshTokenUseCase.ts
 * @description Caso de uso de renovación de token JWT. El frontend lo invoca
 * cuando al token actual le quedan menos de 7 días para expirar. Devuelve un
 * token nuevo con expiración fresca (JWT_EXPIRES_IN, 30d por defecto) sin
 * requerir credenciales — basta con que el JWT actual sea válido (verificado
 * por AuthMiddleware antes de llegar aquí).
 * @module Auth
 * @layer Domain
 *
 * @implements {IRefreshTokenUseCase}
 * @injectable
 * @dependencies IUserRepository, JwtService
 */

import { injectable, inject } from 'inversify';
import type { IRefreshTokenUseCase } from '../../interfaces/usecases/auth/IRefreshTokenUseCase.js';
import type { IUserRepository } from '../../repositories/IUserRepository.js';
import type { AuthResponseDTO } from '../../dtos/auth/auth-response.dto.js';
import { JwtService } from '../../../presentation/services/JwtService.js';
import { TYPES } from '../../../core/types.js';
import { NotFoundException } from '../../../core/exceptions/NotFoundException.js';

/**
 * Genera un token JWT nuevo para el usuario indicado.
 *
 * @implements {IRefreshTokenUseCase}
 * @injectable
 * @dependencies IUserRepository, JwtService
 */
@injectable()
export class RefreshTokenUseCase implements IRefreshTokenUseCase {
  constructor(
    @inject(TYPES.IUserRepository) private readonly userRepo: IUserRepository,
    @inject(TYPES.JwtService)      private readonly jwtService: JwtService,
  ) {}

  /**
   * Verifica que el usuario sigue activo y emite un token JWT nuevo.
   * El token expirado o inválido se rechaza antes (en AuthMiddleware) — este
   * use case asume que el caller ya pasó esa verificación.
   *
   * @param userId — Id del usuario extraído del JWT actual.
   * @returns AuthResponseDTO con el nuevo token (JWT_EXPIRES_IN fresco) y
   *          los datos públicos actualizados del usuario.
   * @throws {NotFoundException} Si el usuario no existe o está soft-deleted
   *         (`findById` ya filtra `deletedAt:null`).
   */
  async execute(userId: string): Promise<AuthResponseDTO> {
    const user = await this.userRepo.findById(userId);
    if (!user) {
      throw new NotFoundException('User', userId);
    }

    const token = this.jwtService.sign({
      userId: user.id,
      email:  user.email,
      role:   user.role,
    });

    return { token, user: user.sanitizeForPublic() };
  }
}
