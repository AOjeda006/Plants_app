/**
 * @file UnauthorizedException.ts
 * @description Excepción para accesos no autorizados (HTTP 401).
 * @module Auth
 * @layer Core
 */

import { HttpException } from './HttpException.js';

/**
 * Lanzar cuando el token JWT es inválido, ha expirado o no se ha proporcionado.
 */
export class UnauthorizedException extends HttpException {
  /**
   * @param message — Mensaje descriptivo del motivo (por defecto genérico).
   */
  constructor(message = 'No autorizado') {
    super(message, 401, 'UNAUTHORIZED');
  }
}
