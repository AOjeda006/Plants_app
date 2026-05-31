/**
 * @file ForbiddenException.ts
 * @description Excepción HTTP 403 Forbidden.
 * Se lanza cuando el usuario autenticado intenta acceder a un recurso
 * al que no tiene permiso (p.ej. completar un recordatorio ajeno).
 * @module Core
 * @layer Core
 */

import { HttpException } from './HttpException.js';

/**
 * Excepción 403 Forbidden.
 */
export class ForbiddenException extends HttpException {
  /**
   * @param message — Mensaje descriptivo del acceso denegado.
   */
  constructor(message = 'Acceso denegado') {
    super(message, 403, 'FORBIDDEN');
  }
}
