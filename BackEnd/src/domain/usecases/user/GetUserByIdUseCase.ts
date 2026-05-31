/**
 * @file GetUserByIdUseCase.ts
 * @description Caso de uso para obtener los datos públicos de un usuario por ID.
 * Usado tanto para el perfil propio (/users/me) como para perfiles ajenos.
 * @module User
 * @layer Domain
 *
 * @implements {IGetUserByIdUseCase}
 * @injectable
 * @dependencies IUserRepository
 */

import { injectable, inject } from 'inversify';
import { TYPES } from '../../../core/types.js';
import type { IGetUserByIdUseCase } from '../../interfaces/usecases/user/IGetUserByIdUseCase.js';
import type { IUserRepository } from '../../repositories/IUserRepository.js';
import type { UserResponseDTO } from '../../dtos/user/user-response.dto.js';
import { NotFoundException } from '../../../core/exceptions/NotFoundException.js';

/**
 * Obtiene el perfil público de un usuario por su ID.
 *
 * @implements {IGetUserByIdUseCase}
 * @injectable
 * @dependencies IUserRepository
 */
@injectable()
export class GetUserByIdUseCase implements IGetUserByIdUseCase {
  constructor(
    @inject(TYPES.IUserRepository) private readonly userRepo: IUserRepository,
  ) {}

  /**
   * @param userId — ID del usuario a consultar.
   * @returns Datos públicos del usuario (sin passwordHash ni fcmToken).
   * @throws {NotFoundException} Si el usuario no existe.
   */
  async execute(userId: string): Promise<UserResponseDTO> {
    const user = await this.userRepo.findById(userId);
    if (!user) throw new NotFoundException('User', userId);

    return {
      id:          user.id,
      name:        user.name,
      email:       user.email,
      role:        user.role,
      photo:       user.photo,
      bannerPhoto: user.bannerPhoto,
      bio:         user.bio,
      location:    user.location,
      locationLat: user.locationLat,
      locationLon: user.locationLon,
      preferences: user.preferences,
      createdAt:   user.createdAt,
      bannedUntil: user.bannedUntil,
    };
  }
}
