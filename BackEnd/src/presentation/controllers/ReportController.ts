/**
 * @file ReportController.ts
 * @description Controlador HTTP para el módulo de reportes de incidencias.
 * Expone POST /reports (cualquier usuario autenticado) para crear un reporte.
 * Los endpoints de administración (listar, resolver) viven en AdminController.
 * @module Admin
 * @layer Presentation
 *
 * @injectable
 * @dependencies MongoDBConnection
 */

import { injectable, inject } from 'inversify';
import { Request, Response, NextFunction, Router } from 'express';
import { ObjectId } from 'mongodb';
import { MongoDBConnection } from '../../data/datasources/mongodb/MongoDBConnection.js';
import { TYPES } from '../../core/types.js';
import { HttpException } from '../../core/exceptions/HttpException.js';
import { createLogger } from '../../core/logger.js';

const logger = createLogger('ReportController');

/** Tipo auxiliar para acceder a req.user sin augmentación global */
type AuthRequest = Request & { user: { id: string; role: string } };

/** Tipos válidos de reporte */
const VALID_TYPES = ['general', 'post', 'comment'] as const;

/**
 * Controlador de reportes de incidencias.
 *
 * @injectable
 * @dependencies MongoDBConnection
 */
@injectable()
export class ReportController {
  constructor(
    @inject(TYPES.MongoDBConnection)
    private readonly db: MongoDBConnection,
  ) {}

  /**
   * Devuelve un Router de Express con las rutas de reportes de usuario.
   * Montar en bootstrap: app.use('/reports', requireAuth, reportController.router()).
   */
  router(): Router {
    const router = Router();
    router.post('/', this.handleCreateReport.bind(this));
    return router;
  }

  /**
   * POST /reports — Crea un nuevo reporte de incidencia.
   *
   * @param req — Body: { type?, targetId?, text, imageUrl? }
   * @param res — 201 con el reporte creado.
   * @param next — Manejador de errores.
   */
  private async handleCreateReport(
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> {
    try {
      const userId = (req as AuthRequest).user.id;
      const {
        type     = 'general',
        targetId,
        text,
        imageUrl,
      } = req.body as {
        type?:     string;
        targetId?: string;
        text:      string;
        imageUrl?: string;
      };

      if (!text || typeof text !== 'string' || text.trim().length === 0) {
        throw new HttpException('El campo "text" es obligatorio', 400, 'VALIDATION_ERROR');
      }

      const reportType = VALID_TYPES.includes(type as typeof VALID_TYPES[number])
        ? (type as typeof VALID_TYPES[number])
        : 'general';

      // Auto-incrementar ticketNumber usando la colección 'counters'.
      const counterResult = await this.db.getDatabase()
        .collection('counters')
        .findOneAndUpdate(
          { _id: 'report_ticket' as any },
          { $inc: { seq: 1 } },
          { upsert: true, returnDocument: 'after' },
        );
      const ticketNumber = (counterResult as any)?.seq ?? 1;

      const doc = {
        _id:          new ObjectId(),
        userId:       new ObjectId(userId),
        type:         reportType,
        targetId:     targetId ? new ObjectId(targetId) : undefined,
        text:         text.trim().slice(0, 1000),
        imageUrl:     imageUrl ?? undefined,
        status:       'pending' as const,
        ticketNumber,
        createdAt:    new Date(),
      };

      await this.db.getDatabase().collection('reports').insertOne(doc);

      logger.debug(`Reporte creado: ${doc._id.toHexString()} (type=${reportType}, user=${userId})`);

      res.status(201).json({
        id:           doc._id.toHexString(),
        userId,
        type:         doc.type,
        targetId,
        text:         doc.text,
        imageUrl:     doc.imageUrl,
        status:       doc.status,
        ticketNumber: doc.ticketNumber,
        createdAt:    doc.createdAt.toISOString(),
      });
    } catch (error) {
      next(error);
    }
  }
}
