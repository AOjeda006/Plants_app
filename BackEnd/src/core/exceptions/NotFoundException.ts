/**
 * @file NotFoundException.ts
 * @description Excepción para recursos no encontrados (HTTP 404).
 * @module Core
 * @layer Core
 */

import { HttpException } from './HttpException.js';

/**
 * Lanzar cuando un recurso buscado no existe en la base de datos.
 */
export class NotFoundException extends HttpException {
  /**
   * @param resource — Nombre del recurso no encontrado (ej: "Plant", "User").
   * @param id — Identificador buscado (opcional).
   */
  constructor(resource: string, id?: string) {
    const message = id
      ? `${resource} con id '${id}' no encontrado`
      : `${resource} no encontrado`;
    super(message, 404, 'NOT_FOUND');
  }
}
