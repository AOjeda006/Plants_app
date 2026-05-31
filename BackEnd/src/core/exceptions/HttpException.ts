/**
 * @file HttpException.ts
 * @description Clase base para todas las excepciones HTTP del backend.
 * El ErrorMiddleware captura estas excepciones y las formatea como { code, message, details }.
 * @module Core
 * @layer Core
 */

/**
 * Excepción HTTP base.
 * Todas las excepciones de dominio deben extender esta clase.
 */
export class HttpException extends Error {
  /** Código de estado HTTP */
  readonly statusCode: number;

  /** Código de error de negocio (ej: "USER_NOT_FOUND", "INVALID_TOKEN") */
  readonly code: string;

  /** Detalles adicionales opcionales (errores de validación, contexto) */
  readonly details?: unknown;

  /**
   * @param message — Mensaje legible del error.
   * @param statusCode — Código HTTP (400, 401, 404, 422, 500...).
   * @param code — Código de error de negocio en UPPER_SNAKE_CASE.
   * @param details — Información adicional opcional.
   */
  constructor(message: string, statusCode: number, code: string, details?: unknown) {
    super(message);
    this.name = this.constructor.name;
    this.statusCode = statusCode;
    this.code = code;
    this.details = details;

    // Restaurar el prototipo correcto (necesario al extender Error en TypeScript)
    Object.setPrototypeOf(this, new.target.prototype);
  }
}
