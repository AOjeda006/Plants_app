/**
 * @file ConflictException.ts
 * @description Excepción HTTP 409 Conflict. Se lanza cuando una operación
 * viola una restricción de unicidad o un estado de recurso esperado.
 * Ejemplo: dar like a un post que ya tiene like del mismo usuario.
 * @module Core
 * @layer Core
 */

import { HttpException } from './HttpException.js';

/**
 * Excepción HTTP 409 Conflict.
 * Extiende [HttpException] con statusCode = 409.
 */
export class ConflictException extends HttpException {
  /**
   * @param message — Mensaje legible del conflicto.
   * @param code    — Código de error de negocio (por defecto 'CONFLICT').
   */
  constructor(message: string, code = 'CONFLICT') {
    super(message, 409, code);
  }
}
