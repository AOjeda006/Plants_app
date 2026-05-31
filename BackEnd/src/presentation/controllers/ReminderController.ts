/**
 * @file ReminderController.ts
 * @description Controlador HTTP del módulo de recordatorios.
 * Expone dos endpoints protegidos por autenticación JWT:
 *   GET  /reminders          → lista los recordatorios activos del usuario.
 *   POST /reminders/:id/complete → marca un recordatorio como completado.
 * @module Reminders
 * @layer Presentation
 *
 * @injectable
 * @dependencies IGetUserRemindersUseCase, IMarkReminderCompletedUseCase
 */

import { injectable, inject } from 'inversify';
import { Request, Response, NextFunction, Router } from 'express';
import type { IGetUserRemindersUseCase } from '../../domain/interfaces/usecases/reminders/IGetUserRemindersUseCase.js';
import type { IMarkReminderCompletedUseCase } from '../../domain/interfaces/usecases/reminders/IMarkReminderCompletedUseCase.js';
import { TYPES } from '../../core/types.js';
import { createLogger } from '../../core/logger.js';

const logger = createLogger('ReminderController');

/**
 * Controlador de rutas de recordatorios.
 *
 * @injectable
 * @dependencies IGetUserRemindersUseCase, IMarkReminderCompletedUseCase
 */
@injectable()
export class ReminderController {
  constructor(
    @inject(TYPES.IGetUserRemindersUseCase)      private readonly getUserReminders: IGetUserRemindersUseCase,
    @inject(TYPES.IMarkReminderCompletedUseCase) private readonly markCompleted: IMarkReminderCompletedUseCase,
  ) {}

  /**
   * Devuelve un Router de Express con las rutas del módulo de recordatorios.
   * Usar en bootstrap(): app.use('/reminders', requireAuth, reminderController.router()).
   */
  router(): Router {
    const router = Router();
    router.get('/',               this.handleGetReminders.bind(this));
    router.post('/:id/complete',  this.handleMarkCompleted.bind(this));
    return router;
  }

  /**
   * GET /reminders
   * Devuelve la lista de recordatorios activos del usuario autenticado.
   *
   * @param req — Request con req.user.id inyectado por AuthMiddleware.
   * @param res — Response con array de ReminderResponseDTO.
   * @param next — Manejador de errores.
   */
  private async handleGetReminders(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = (req as Request & { user: { userId: string } }).user.userId;
      const result = await this.getUserReminders.execute(userId);
      res.json(result);
      logger.debug(`Recordatorios devueltos para usuario ${userId}: ${result.length}`);
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /reminders/:id/complete
   * Marca el recordatorio indicado como completado.
   * Valida que el recordatorio pertenece al usuario autenticado.
   *
   * @param req — Request con params.id y req.user.id.
   * @param res — 204 No Content si todo va bien.
   * @param next — Manejador de errores (404 si no existe, 403 si ajeno).
   */
  private async handleMarkCompleted(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const reminderId = req.params['id'] as string;
      const userId     = (req as Request & { user: { userId: string } }).user.userId;
      await this.markCompleted.execute(reminderId, userId);
      res.status(204).send();
      logger.debug(`Recordatorio ${reminderId} marcado como completado por usuario ${userId}`);
    } catch (error) {
      next(error);
    }
  }
}
