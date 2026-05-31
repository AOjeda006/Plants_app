/**
 * @file IGetUserByIdUseCase.ts
 * @description Interfaz del caso de uso para obtener el perfil de un usuario por ID.
 * @module User
 * @layer Domain
 */

import type { UserResponseDTO } from '../../../dtos/user/user-response.dto.js';

export interface IGetUserByIdUseCase {
  /**
   * @param userId — ID del usuario a obtener.
   * @returns Datos públicos del usuario.
   * @throws {NotFoundException} Si el usuario no existe.
   */
  execute(userId: string): Promise<UserResponseDTO>;
}
