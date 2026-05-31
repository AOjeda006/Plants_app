/**
 * @file IUpdateUserPreferencesUseCase.ts
 * @description Interfaz del caso de uso para actualizar las preferencias del usuario.
 * @module User
 * @layer Domain
 */

import type { UpdatePreferencesRequestDto } from '../../../dtos/user/update-preferences-request.dto.js';
import type { UserResponseDTO } from '../../../dtos/user/user-response.dto.js';

export interface IUpdateUserPreferencesUseCase {
  /**
   * @param userId — ID del usuario autenticado.
   * @param dto — Preferencias a actualizar (parcial).
   * @returns Datos públicos del usuario con preferencias actualizadas.
   * @throws {NotFoundException} Si el usuario no existe.
   */
  execute(userId: string, dto: UpdatePreferencesRequestDto): Promise<UserResponseDTO>;
}
