/**
 * @file BanMiddleware.ts
 * @description Middleware que verifica si el usuario autenticado está baneado
 * temporalmente. Bloquea operaciones de escritura (POST, PUT, DELETE) en rutas
 * de contenido (community, chat) si bannedUntil > now.
 * No bloquea lecturas (GET) ni operaciones sobre el propio perfil.
 * @module Core
 * @layer Core
 *
 * @dependencies MongoDBConnection
 */

import { Request, Response, NextFunction } from 'express';
import { ObjectId } from 'mongodb';
import { MongoDBConnection } from '../../data/datasources/mongodb/MongoDBConnection.js';
import { ForbiddenException } from '../exceptions/ForbiddenException.js';

/**
 * Crea una instancia del middleware de verificación de baneo.
 * Solo bloquea métodos de escritura (POST, PUT, DELETE) en rutas de contenido.
 * Las lecturas (GET) siempre se permiten para que el usuario baneado pueda seguir
 * viendo la app y su banner de suspensión.
 *
 * @param db — Instancia de MongoDBConnection para consultar bannedUntil.
 * @returns Función middleware de Express.
 */
export function createBanMiddleware(db: MongoDBConnection) {
  return async function banMiddleware(
    req: Request,
    _res: Response,
    next: NextFunction,
  ): Promise<void> {
    // Solo bloquear operaciones de escritura.
    if (req.method === 'GET') return next();

    // Permitir marcar mensajes como leídos aunque el usuario esté baneado
    // (POST /chat/:id/read). El baneado puede leer chat pero no escribir.
    if (req.method === 'POST' && req.originalUrl.match(/\/chat\/[^/]+\/read$/)) {
      return next();
    }

    const user = (req as Request & { user?: { id?: string; userId?: string; role?: string } }).user;
    const userId = user?.userId ?? user?.id;
    if (!userId) return next();

    // Los admins nunca son bloqueados por baneo — necesitan acceso completo para moderar.
    if (user?.role === 'admin') return next();

    try {
      const doc = await db.getDatabase()
        .collection('users')
        .findOne(
          { _id: new ObjectId(userId) },
          { projection: { bannedUntil: 1 } },
        );

      if (doc?.bannedUntil && new Date(doc.bannedUntil as Date) > new Date()) {
        const until = new Date(doc.bannedUntil as Date).toLocaleDateString('es-ES');
        throw new ForbiddenException(`Tu cuenta está suspendida hasta el ${until}`);
      }

      next();
    } catch (error) {
      next(error);
    }
  };
}
