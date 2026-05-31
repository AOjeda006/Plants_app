/**
 * @file NotificationController.ts
 * @description Controlador HTTP del módulo de notificaciones in-app.
 * Expone tres endpoints protegidos por autenticación JWT:
 *   GET    /notifications         → lista las notificaciones del usuario.
 *   PUT    /notifications/read    → marca todas las notificaciones como leídas.
 *   DELETE /notifications         → elimina todas las notificaciones del usuario.
 * @module Reminders
 * @layer Presentation
 *
 * @injectable
 * @dependencies IGetUserNotificationsUseCase, IMarkNotificationsReadUseCase,
 *              IDeleteNotificationsUseCase
 */

import { injectable, inject } from 'inversify';
import { Request, Response, NextFunction, Router } from 'express';
import type { IGetUserNotificationsUseCase } from '../../domain/interfaces/usecases/notifications/IGetUserNotificationsUseCase.js';
import type { IMarkNotificationsReadUseCase } from '../../domain/interfaces/usecases/notifications/IMarkNotificationsReadUseCase.js';
import type { IDeleteNotificationsUseCase } from '../../domain/interfaces/usecases/notifications/IDeleteNotificationsUseCase.js';
import { TYPES } from '../../core/types.js';
import { createLogger } from '../../core/logger.js';

const logger = createLogger('NotificationController');

/** Tipo auxiliar para acceder al userId inyectado por AuthMiddleware */
type AuthRequest = Request & { user: { userId: string } };

/**
 * Controlador de rutas de notificaciones in-app.
 *
 * @injectable
 * @dependencies IGetUserNotificationsUseCase, IMarkNotificationsReadUseCase,
 *              IDeleteNotificationsUseCase
 */
@injectable()
export class NotificationController {
  constructor(
    @inject(TYPES.IGetUserNotificationsUseCase)  private readonly getNotifications: IGetUserNotificationsUseCase,
    @inject(TYPES.IMarkNotificationsReadUseCase) private readonly markRead: IMarkNotificationsReadUseCase,
    @inject(TYPES.IDeleteNotificationsUseCase)   private readonly deleteNotifications: IDeleteNotificationsUseCase,
  ) {}

  /**
   * Devuelve un Router de Express con las rutas del módulo de notificaciones.
   * Usar en bootstrap(): app.use('/notifications', requireAuth, notificationController.router()).
   */
  router(): Router {
    const router = Router();
    // PUT /read debe ir ANTES de rutas con parámetros para evitar colisión
    router.get('/',      this.handleGetNotifications.bind(this));
    router.put('/read',  this.handleMarkRead.bind(this));
    router.delete('/',   this.handleDeleteNotifications.bind(this));
    return router;
  }

  /**
   * GET /notifications
   * Devuelve la lista de notificaciones in-app del usuario autenticado.
   *
   * @param req — Request con req.user.userId inyectado por AuthMiddleware.
   * @param res — Response con array de NotificationResponseDTO.
   * @param next — Manejador de errores.
   */
  private async handleGetNotifications(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = (req as AuthRequest).user.userId;
      const result = await this.getNotifications.execute(userId);
      res.json(result);
      logger.debug(`Notificaciones devueltas para usuario ${userId}: ${result.length}`);
    } catch (error) {
      next(error);
    }
  }

  /**
   * PUT /notifications/read
   * Marca todas las notificaciones del usuario como leídas.
   *
   * @param req — Request con req.user.userId.
   * @param res — 204 No Content.
   * @param next — Manejador de errores.
   */
  private async handleMarkRead(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = (req as AuthRequest).user.userId;
      const ids    = Array.isArray(req.body?.ids) ? req.body.ids as string[] : undefined;
      await this.markRead.execute(userId, ids);
      res.status(204).send();
      logger.debug(`Notificaciones marcadas como leídas para usuario ${userId} (ids: ${ids ? ids.length : 'todas'})`);
    } catch (error) {
      next(error);
    }
  }

  /**
   * DELETE /notifications
   * Elimina todas las notificaciones del usuario autenticado.
   *
   * @param req — Request con req.user.userId.
   * @param res — 204 No Content.
   * @param next — Manejador de errores.
   */
  private async handleDeleteNotifications(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = (req as AuthRequest).user.userId;
      const ids    = Array.isArray(req.body?.ids) ? req.body.ids as string[] : undefined;
      await this.deleteNotifications.execute(userId, ids);
      res.status(204).send();
      logger.debug(`Notificaciones eliminadas para usuario ${userId} (ids: ${ids ? ids.length : 'todas'})`);
    } catch (error) {
      next(error);
    }
  }
}
