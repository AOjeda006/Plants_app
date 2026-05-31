/**
 * @file IValidateTokenUseCase.ts
 * @description Interfaz del caso de uso de validación de token JWT.
 * @module Auth
 * @layer Domain
 */

import type { UserResponseDTO } from '../../../dtos/user/user-response.dto.js';

/** Contrato del use case de validación de token. */
export interface IValidateTokenUseCase {
  /**
   * @param token — Token JWT a validar.
   * @returns Datos públicos del usuario si el token es válido.
   * @throws {UnauthorizedException} Si el token es inválido o ha expirado.
   */
  execute(token: string): Promise<UserResponseDTO>;
}
