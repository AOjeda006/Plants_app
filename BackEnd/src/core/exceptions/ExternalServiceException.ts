/**
 * @file ExternalServiceException.ts
 * @description Excepción para fallos en servicios externos (WeatherAPI, Cloudinary, Firebase).
 * @module Core
 * @layer Core
 */

import { HttpException } from './HttpException.js';

/**
 * Lanzar cuando un servicio externo devuelve error o no está disponible.
 */
export class ExternalServiceException extends HttpException {
  /**
   * @param service — Nombre del servicio externo (ej: "WeatherAPI", "Cloudinary").
   * @param details — Detalle del error original (opcional).
   */
  constructor(service: string, details?: unknown) {
    super(`Error al comunicarse con el servicio externo: ${service}`, 502, 'EXTERNAL_SERVICE_ERROR', details);
  }
}
