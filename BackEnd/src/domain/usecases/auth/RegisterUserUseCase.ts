/**
 * @file RegisterUserUseCase.ts
 * @description Caso de uso de registro de nuevo usuario.
 * Valida email único, hashea la contraseña y crea el usuario.
 * @module Auth
 * @layer Domain
 *
 * @implements {IRegisterUserUseCase}
 * @injectable
 * @dependencies IUserRepository, HashService, JwtService
 */

import { injectable, inject } from 'inversify';
import type { IRegisterUserUseCase } from '../../interfaces/usecases/auth/IRegisterUserUseCase.js';
import type { IUserRepository } from '../../repositories/IUserRepository.js';
import type { RegisterRequestDTO } from '../../dtos/auth/register-request.dto.js';
import type { AuthResponseDTO } from '../../dtos/auth/auth-response.dto.js';
import { HashService } from '../../../presentation/services/HashService.js';
import { JwtService } from '../../../presentation/services/JwtService.js';
import { User } from '../../entities/User.js';
import { TYPES } from '../../../core/types.js';
import { HttpException } from '../../../core/exceptions/HttpException.js';

/**
 * Registra un nuevo usuario en el sistema.
 *
 * @implements {IRegisterUserUseCase}
 * @injectable
 * @dependencies IUserRepository, HashService, JwtService
 */
@injectable()
export class RegisterUserUseCase implements IRegisterUserUseCase {
  constructor(
    @inject(TYPES.IUserRepository) private readonly userRepo: IUserRepository,
    @inject(TYPES.HashService)     private readonly hashService: HashService,
    @inject(TYPES.JwtService)      private readonly jwtService: JwtService,
  ) {}

  /**
   * Registra el usuario: valida unicidad del email, hashea la contraseña,
   * crea el registro en BD y devuelve token + usuario.
   *
   * @param dto — Datos de registro validados.
   * @returns AuthResponseDTO con token JWT y datos públicos del usuario.
   * @throws {HttpException} 409 si el email ya está registrado.
   */
  async execute(dto: RegisterRequestDTO): Promise<AuthResponseDTO> {
    // 1. Verificar que el email no está en uso
    const existing = await this.userRepo.findByEmail(dto.email);
    if (existing) {
      throw new HttpException('El email ya está registrado', 409, 'EMAIL_ALREADY_EXISTS');
    }

    // 2. Hashear contraseña
    const passwordHash = await this.hashService.hash(dto.password);

    // 3. Crear entidad y persistir
    const now = new Date();
    const user = await this.userRepo.create(
      new User({
        id: '',       // el repositorio asigna el ObjectId real
        role: 'user', // los nuevos usuarios siempre inician como 'user'
        name: dto.name,
        email: dto.email.toLowerCase(),
        passwordHash,
        createdAt: now,
        updatedAt: now,
      }),
    );

    // 4. Generar token JWT
    const token = this.jwtService.sign({ userId: user.id, email: user.email, role: user.role });

    return { token, user: user.sanitizeForPublic() };
  }
}
