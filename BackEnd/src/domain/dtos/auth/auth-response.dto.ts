/**
 * @file auth-response.dto.ts
 * @description DTO de respuesta de autenticación (register y login).
 * @module Auth
 * @layer Domain
 */

import { UserResponseDTO } from '../user/user-response.dto.js';

/**
 * Respuesta que incluye el token JWT y los datos públicos del usuario.
 */
export interface AuthResponseDTO {
  /** Token JWT para autorizar peticiones futuras */
  token: string;
  /** Datos públicos del usuario (sin passwordHash ni fcmToken) */
  user: UserResponseDTO;
}
