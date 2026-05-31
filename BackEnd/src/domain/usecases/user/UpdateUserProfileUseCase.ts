/**
 * @file UpdateUserProfileUseCase.ts
 * @description Caso de uso para actualizar el perfil público del usuario autenticado.
 * Actualiza nombre, bio y ubicación. La foto se gestiona en /upload/image.
 * @module User
 * @layer Domain
 *
 * @implements {IUpdateUserProfileUseCase}
 * @injectable
 * @dependencies IUserRepository
 */

import { injectable, inject } from 'inversify';
import { TYPES } from '../../../core/types.js';
import type { IUpdateUserProfileUseCase } from '../../interfaces/usecases/user/IUpdateUserProfileUseCase.js';
import type { IUserRepository } from '../../repositories/IUserRepository.js';
import type { UpdateProfileRequestDto } from '../../dtos/user/update-profile-request.dto.js';
import type { UserResponseDTO } from '../../dtos/user/user-response.dto.js';
import { NotFoundException } from '../../../core/exceptions/NotFoundException.js';

/**
 * Actualiza nombre, bio y ubicación del usuario autenticado.
 *
 * @implements {IUpdateUserProfileUseCase}
 * @injectable
 * @dependencies IUserRepository
 */
@injectable()
export class UpdateUserProfileUseCase implements IUpdateUserProfileUseCase {
  constructor(
    @inject(TYPES.IUserRepository) private readonly userRepo: IUserRepository,
  ) {}

  /**
   * @param userId — ID del usuario autenticado.
   * @param dto — Campos a actualizar (todos opcionales).
   * @returns Datos públicos del usuario actualizado.
   * @throws {NotFoundException} Si el usuario no existe.
   */
  async execute(userId: string, dto: UpdateProfileRequestDto): Promise<UserResponseDTO> {
    // Construir solo los campos presentes en el DTO para evitar sobrescribir con undefined
    const updates: Record<string, unknown> = {};
    if (dto.name        !== undefined) updates['name']        = dto.name;
    if (dto.bio         !== undefined) updates['bio']         = dto.bio;
    if (dto.location    !== undefined) updates['location']    = dto.location;
    if (dto.locationLat !== undefined) updates['locationLat'] = dto.locationLat;
    if (dto.locationLon !== undefined) updates['locationLon'] = dto.locationLon;
    if (dto.photo       !== undefined) updates['photo']       = dto.photo;
    if (dto.bannerPhoto !== undefined) updates['bannerPhoto'] = dto.bannerPhoto;

    const user = await this.userRepo.update(userId, updates);

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
