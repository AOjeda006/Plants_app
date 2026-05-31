/**
 * @file SanitizationMiddleware.ts
 * @description Middleware de saneamiento del cuerpo de la petición.
 * Elimina scripts, recorta cadenas y normaliza arrays para prevenir XSS e inyecciones.
 * @module Core
 * @layer Core
 */

import { Request, Response, NextFunction } from 'express';

/**
 * Sanea recursivamente un valor de entrada:
 * - Strings: elimina etiquetas HTML/script y recorta espacios.
 * - Arrays: sanea cada elemento.
 * - Objetos: sanea cada propiedad.
 * - Otros tipos (number, boolean, null): se devuelven sin modificar.
 *
 * @param value — Valor a sanear.
 * @returns Valor saneado.
 * @private
 */
function sanitizeValue(value: unknown): unknown {
  if (typeof value === 'string') {
    return value
      .trim()
      // Eliminar etiquetas HTML y scripts para prevenir XSS
      .replace(/<[^>]*>/g, '')
      // Eliminar caracteres de control
      .replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g, '');
  }

  if (Array.isArray(value)) {
    return value.map(sanitizeValue);
  }

  if (value !== null && typeof value === 'object') {
    const sanitized: Record<string, unknown> = {};
    for (const [key, val] of Object.entries(value as Record<string, unknown>)) {
      sanitized[key] = sanitizeValue(val);
    }
    return sanitized;
  }

  return value;
}

/**
 * Middleware que sanea req.body antes de que llegue a los controladores.
 * No modifica campos de tipo número, booleano ni null para no romper DTOs.
 */
export function sanitizationMiddleware(req: Request, _res: Response, next: NextFunction): void {
  if (req.body && typeof req.body === 'object') {
    req.body = sanitizeValue(req.body);
  }
  next();
}
