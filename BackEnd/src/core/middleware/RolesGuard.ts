/**
 * @file RolesGuard.ts
 * @description Middleware de autorización basado en roles y permisos.
 * Consulta la policyMatrix para verificar si el rol del usuario autenticado
 * tiene permiso para ejecutar la acción solicitada sobre el recurso dado.
 * Debe aplicarse DESPUÉS de AuthMiddleware (req.user debe existir).
 * @module Core
 * @layer Core
 *
 * @dependencies policyMatrix, AuthMiddleware, ForbiddenException
 */

import { Request, Response, NextFunction } from 'express';
import type { AuthenticatedRequest } from './AuthMiddleware.js';
import { hasPermission, type PolicyAction, type PolicyResource } from '../policies/policyMatrix.js';
import { ForbiddenException } from '../exceptions/ForbiddenException.js';

/**
 * Factory de middleware de autorización.
 * Devuelve un middleware de Express que verifica si el usuario autenticado
 * tiene el permiso indicado para actuar sobre el recurso dado.
 *
 * Uso: router.post('/:id/approve', requirePermission('approve_species', 'species'), handler)
 *
 * @param action   — Acción que se intenta realizar (ej: 'approve_species').
 * @param resource — Recurso sobre el que se actúa (ej: 'species').
 * @returns Middleware de Express.
 */
export function requirePermission(action: PolicyAction, resource: PolicyResource) {
  return function rolesGuard(req: Request, _res: Response, next: NextFunction): void {
    const role = (req as AuthenticatedRequest).user?.role;

    if (!hasPermission(role, action, resource)) {
      return next(
        new ForbiddenException(
          `Acción '${action}' no permitida sobre '${resource}' para el rol '${role ?? 'desconocido'}'`,
        ),
      );
    }

    next();
  };
}
