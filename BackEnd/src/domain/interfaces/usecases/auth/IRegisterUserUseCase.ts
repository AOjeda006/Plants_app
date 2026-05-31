/**
 * @file IRegisterUserUseCase.ts
 * @description Interfaz del caso de uso de registro de usuario.
 * @module Auth
 * @layer Domain
 */

import type { RegisterRequestDTO } from '../../../dtos/auth/register-request.dto.js';
import type { AuthResponseDTO } from '../../../dtos/auth/auth-response.dto.js';

/** Contrato del use case de registro. */
export interface IRegisterUserUseCase {
  /**
   * @param dto — Datos de registro validados.
   * @returns Token JWT y datos públicos del usuario creado.
   */
  execute(dto: RegisterRequestDTO): Promise<AuthResponseDTO>;
}
