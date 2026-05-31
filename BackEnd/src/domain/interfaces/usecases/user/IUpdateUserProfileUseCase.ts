/**
 * @file IUpdateUserProfileUseCase.ts
 * @description Interfaz del caso de uso para actualizar el perfil del usuario.
 * @module User
 * @layer Domain
 */

import type { UpdateProfileRequestDto } from '../../../dtos/user/update-profile-request.dto.js';
import type { UserResponseDTO } from '../../../dtos/user/user-response.dto.js';

export interface IUpdateUserProfileUseCase {
  /**
   * @param userId — ID del usuario autenticado.
   * @param dto — Campos a actualizar (nombre, bio, ubicación, foto).
   * @returns Datos públicos del usuario actualizado.
   * @throws {NotFoundException} Si el usuario no existe.
   */
  execute(userId: string, dto: UpdateProfileRequestDto): Promise<UserResponseDTO>;
}
