/**
 * @file UpdateUserPreferencesUseCase.ts
 * @description Caso de uso para actualizar las preferencias de notificación y comportamiento.
 * Hace merge de las preferencias actuales con las nuevas, preservando los campos no enviados.
 * @module User
 * @layer Domain
 *
 * @implements {IUpdateUserPreferencesUseCase}
 * @injectable
 * @dependencies IUserRepository
 */

import { injectable, inject } from 'inversify';
import { TYPES } from '../../../core/types.js';
import type { IUpdateUserPreferencesUseCase } from '../../interfaces/usecases/user/IUpdateUserPreferencesUseCase.js';
import type { IUserRepository } from '../../repositories/IUserRepository.js';
import type { UpdatePreferencesRequestDto } from '../../dtos/user/update-preferences-request.dto.js';
import type { UserResponseDTO } from '../../dtos/user/user-response.dto.js';
import { NotFoundException } from '../../../core/exceptions/NotFoundException.js';

/**
 * Actualiza las preferencias del usuario haciendo merge con las actuales.
 *
 * @implements {IUpdateUserPreferencesUseCase}
 * @injectable
 * @dependencies IUserRepository
 */
@injectable()
export class UpdateUserPreferencesUseCase implements IUpdateUserPreferencesUseCase {
  constructor(
    @inject(TYPES.IUserRepository) private readonly userRepo: IUserRepository,
  ) {}

  /**
   * @param userId — ID del usuario autenticado.
   * @param dto — Preferencias a actualizar (parcial; campos omitidos conservan su valor).
   * @returns Datos públicos del usuario con preferencias actualizadas.
   * @throws {NotFoundException} Si el usuario no existe.
   */
  async execute(userId: string, dto: UpdatePreferencesRequestDto): Promise<UserResponseDTO> {
    const existing = await this.userRepo.findById(userId);
    if (!existing) throw new NotFoundException('User', userId);

    // Merge: solo los campos explícitamente enviados sobreescriben los actuales
    const mergedPreferences = {
      ...existing.preferences,
      ...(dto.appearInChatSearch        !== undefined && { appearInChatSearch:        dto.appearInChatSearch }),
      ...(dto.considerWeatherByDefault  !== undefined && { considerWeatherByDefault:  dto.considerWeatherByDefault }),
      ...(dto.isPrivate                 !== undefined && { isPrivate:                 dto.isPrivate }),
      // Persistir el toggle push si llega en el DTO.
      ...(dto.pushNotifications         !== undefined && { pushNotifications:         dto.pushNotifications }),
    };

    const user = await this.userRepo.update(userId, { preferences: mergedPreferences });

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
