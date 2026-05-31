/**
 * @file ValidationException.ts
 * @description Excepción para errores de validación de entrada (HTTP 422).
 * @module Core
 * @layer Core
 */

import { HttpException } from './HttpException.js';

/**
 * Error de un campo individual en la validación.
 */
export interface ValidationError {
  field: string;
  message: string;
}

/**
 * Lanzar cuando class-validator detecta errores en el DTO de entrada.
 * Incluye el detalle de qué campos fallaron y por qué.
 */
export class ValidationException extends HttpException {
  /**
   * @param errors — Lista de errores por campo.
   */
  constructor(errors: ValidationError[]) {
    super('Error de validación en los datos de entrada', 422, 'VALIDATION_ERROR', errors);
  }
}
