/**
 * @file IRefreshTokenUseCase.ts
 * @description Interfaz del caso de uso de refresh de token JWT.
 * @module Auth
 * @layer Domain
 */

import type { AuthResponseDTO } from '../../../dtos/auth/auth-response.dto.js';

/** Contrato del use case de refresh de token. */
export interface IRefreshTokenUseCase {
  /**
   * Genera un nuevo token JWT con expiración fresca (30d) para el usuario indicado.
   * Verifica previamente que el usuario sigue existiendo y no está soft-deleted.
   *
   * @param userId — Id del usuario extraído del JWT actual (validado por AuthMiddleware).
   * @returns AuthResponseDTO con el nuevo token y los datos públicos del usuario.
   * @throws {NotFoundException} Si el usuario ya no existe o está soft-deleted.
   */
  execute(userId: string): Promise<AuthResponseDTO>;
}
