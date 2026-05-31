/**
 * @file ownershipValidator.ts
 * @description Validador de ownership para recursos del usuario.
 * Centraliza la verificación de que el usuario autenticado es propietario del recurso.
 * @module Plants
 * @layer Presentation
 */

import { UnauthorizedException } from '../../core/exceptions/UnauthorizedException.js';

/**
 * Verifica que el userId del recurso coincide con el del usuario autenticado.
 * Se usa en use cases y controllers para evitar acceso a recursos ajenos.
 *
 * @param resourceUserId — UserId almacenado en el recurso (planta, post, etc.).
 * @param requestingUserId — UserId del usuario autenticado en la request.
 * @param resourceName — Nombre del recurso para el mensaje de error (ej: 'Plant', 'Post').
 * @throws {UnauthorizedException} Si los ids no coinciden.
 */
export function verifyOwnership(
  resourceUserId: string,
  requestingUserId: string,
  resourceName: string = 'Resource',
): void {
  if (resourceUserId !== requestingUserId) {
    throw new UnauthorizedException(
      `No tienes permisos para acceder a este ${resourceName}`,
    );
  }
}
