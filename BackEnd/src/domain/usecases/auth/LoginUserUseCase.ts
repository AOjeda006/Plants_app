/**
 * @file LoginUserUseCase.ts
 * @description Caso de uso de login de usuario.
 * Verifica credenciales, genera token JWT y devuelve datos públicos del usuario.
 * @module Auth
 * @layer Domain
 *
 * @implements {ILoginUserUseCase}
 * @injectable
 * @dependencies IUserRepository, HashService, JwtService
 */

import { injectable, inject } from 'inversify';
import type { ILoginUserUseCase } from '../../interfaces/usecases/auth/ILoginUserUseCase.js';
import type { IUserRepository } from '../../repositories/IUserRepository.js';
import type { LoginRequestDTO } from '../../dtos/auth/login-request.dto.js';
import type { AuthResponseDTO } from '../../dtos/auth/auth-response.dto.js';
import { HashService } from '../../../presentation/services/HashService.js';
import { JwtService } from '../../../presentation/services/JwtService.js';
import { TYPES } from '../../../core/types.js';
import { UnauthorizedException } from '../../../core/exceptions/UnauthorizedException.js';

/**
 * Autentica al usuario verificando email + contraseña.
 *
 * @implements {ILoginUserUseCase}
 * @injectable
 * @dependencies IUserRepository, HashService, JwtService
 */
@injectable()
export class LoginUserUseCase implements ILoginUserUseCase {
  constructor(
    @inject(TYPES.IUserRepository) private readonly userRepo: IUserRepository,
    @inject(TYPES.HashService)     private readonly hashService: HashService,
    @inject(TYPES.JwtService)      private readonly jwtService: JwtService,
  ) {}

  /**
   * Verifica email y contraseña, genera y devuelve un token JWT.
   * El mensaje de error es genérico para no revelar si el email existe.
   *
   * @param dto — Credenciales del usuario.
   * @returns AuthResponseDTO con token JWT y datos públicos del usuario.
   * @throws {UnauthorizedException} Si las credenciales son incorrectas.
   */
  async execute(dto: LoginRequestDTO): Promise<AuthResponseDTO> {
    // 1. Buscar usuario por email
    const user = await this.userRepo.findByEmail(dto.email);

    // 2. Validar credenciales (mensaje genérico por seguridad)
    const INVALID_CREDENTIALS = 'Credenciales incorrectas';

    if (!user) {
      throw new UnauthorizedException(INVALID_CREDENTIALS);
    }

    const passwordValid = await this.hashService.compare(dto.password, user.passwordHash);
    if (!passwordValid) {
      throw new UnauthorizedException(INVALID_CREDENTIALS);
    }

    // 3. Generar token y devolver respuesta
    const token = this.jwtService.sign({ userId: user.id, email: user.email, role: user.role });

    return { token, user: user.sanitizeForPublic() };
  }
}
