/**
 * @file ILoginUserUseCase.ts
 * @description Interfaz del caso de uso de login de usuario.
 * @module Auth
 * @layer Domain
 */

import type { LoginRequestDTO } from '../../../dtos/auth/login-request.dto.js';
import type { AuthResponseDTO } from '../../../dtos/auth/auth-response.dto.js';

/** Contrato del use case de login. */
export interface ILoginUserUseCase {
  /**
   * @param dto — Credenciales validadas.
   * @returns Token JWT y datos públicos del usuario.
   */
  execute(dto: LoginRequestDTO): Promise<AuthResponseDTO>;
}
