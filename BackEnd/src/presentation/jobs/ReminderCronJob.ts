/**
 * @file ReminderCronJob.ts
 * @description Cron job para el procesamiento periódico de recordatorios pendientes.
 * Delega toda la lógica de negocio en IProcessPendingRemindersUseCase.
 * El job se ejecuta cada día a las 00:00 y gestiona el lock distribuido
 * internamente en el use case, de modo que este archivo no contiene lógica de dominio.
 * @module Reminders
 * @layer Presentation
 *
 * @injectable
 * @dependencies IProcessPendingRemindersUseCase
 */

import { injectable, inject } from 'inversify';
import { schedule, ScheduledTask } from 'node-cron';
import { TYPES } from '../../core/types.js';
import type { IProcessPendingRemindersUseCase } from '../../domain/interfaces/usecases/reminders/IProcessPendingRemindersUseCase.js';
import { createLogger } from '../../core/logger.js';

const logger = createLogger('ReminderCronJob');

/** Expresión cron: 00:00 diario. */
const CRON_SCHEDULE = '0 0 * * *';

/**
 * Cron job de recordatorios.
 * Inicia el scheduler en start() y lo detiene en stop().
 *
 * @injectable
 * @dependencies IProcessPendingRemindersUseCase
 */
@injectable()
export class ReminderCronJob {
  private task: ScheduledTask | null = null;

  constructor(
    @inject(TYPES.IProcessPendingRemindersUseCase)
    private readonly processUseCase: IProcessPendingRemindersUseCase,
  ) {}

  /**
   * Inicia el cron job de procesamiento de recordatorios.
   * El scheduler es idempotente: llamadas adicionales no crean tareas duplicadas.
   */
  start(): void {
    if (this.task) {
      logger.warn('ReminderCronJob ya estaba iniciado — ignorando llamada duplicada');
      return;
    }

    this.task = schedule(CRON_SCHEDULE, async () => {
      logger.debug('ReminderCronJob: tick — procesando recordatorios pendientes');
      try {
        await this.processUseCase.execute();
      } catch (err) {
        // El use case ya maneja errores individuales; este catch cubre fallos inesperados
        logger.error(`ReminderCronJob: error inesperado — ${(err as Error).message}`);
      }
    });

    logger.info(`ReminderCronJob iniciado (schedule: "${CRON_SCHEDULE}")`);
  }

  /**
   * Detiene el cron job y libera recursos.
   * Se llama en el shutdown de la aplicación.
   */
  stop(): void {
    if (!this.task) return;
    this.task.stop();
    this.task = null;
    logger.info('ReminderCronJob detenido');
  }
}
