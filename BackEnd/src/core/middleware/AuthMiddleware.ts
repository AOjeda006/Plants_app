/**
 * @file AuthMiddleware.ts
 * @description Middleware de autenticación JWT.
 * Extrae el Bearer token de la cabecera Authorization, lo verifica con JwtService
 * y adjunta el payload del usuario a req.user para su uso en los controladores.
 * @module Auth
 * @layer Core
 *
 * @dependencies JwtService
 */

import { Request, Response, NextFunction } from 'express';
import { JwtService, UserPayload } from '../../presentation/services/JwtService.js';
import { UnauthorizedException } from '../exceptions/UnauthorizedException.js';
import { createLogger } from '../logger.js';

const logger = createLogger('AuthMiddleware');

/** Extensión de Request para incluir el usuario autenticado */
export interface AuthenticatedRequest extends Request {
  user: UserPayload;
}

/**
 * Extrae el Bearer token de la cabecera Authorization.
 *
 * @param req — Petición HTTP.
 * @returns Token JWT o null si no existe.
 * @private
 */
function extractToken(req: Request): string | null {
  const auth = req.headers.authorization;
  if (!auth?.startsWith('Bearer ')) return null;
  return auth.slice(7);
}

/**
 * Crea una instancia del middleware de autenticación con el JwtService inyectado.
 * Usar en rutas protegidas: router.use(createAuthMiddleware(jwtService)).
 *
 * @param jwtService — Instancia del servicio JWT.
 * @returns Función middleware de Express.
 */
export function createAuthMiddleware(jwtService: JwtService) {
  return function authMiddleware(
    req: Request,
    _res: Response,
    next: NextFunction,
  ): void {
    const token = extractToken(req);

    if (!token) {
      return next(new UnauthorizedException('Token no proporcionado'));
    }

    try {
      const payload = jwtService.verify(token);
      (req as AuthenticatedRequest).user = payload;
      logger.debug(`Usuario autenticado: ${payload.userId}`);
      next();
    } catch (err) {
      next(err);
    }
  };
}
