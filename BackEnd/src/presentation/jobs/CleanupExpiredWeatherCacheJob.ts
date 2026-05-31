/**
 * @file CleanupExpiredWeatherCacheJob.ts
 * @description Cron job para eliminar entradas de caché meteorológica expiradas.
 * Elimina documentos cuyo campo expiresAt sea anterior a la fecha actual.
 * Se ejecuta cada hora para mantener la colección weatherCache limpia.
 * TFG: frecuencia ajustable; en desarrollo se puede reducir para pruebas.
 * @module Weather
 * @layer Presentation
 *
 * @injectable
 * @dependencies MongoDBConnection
 */

import { injectable, inject } from 'inversify';
import { schedule, ScheduledTask } from 'node-cron';
import { MongoDBConnection } from '../../data/datasources/mongodb/MongoDBConnection.js';
import { TYPES } from '../../core/types.js';
import { createLogger } from '../../core/logger.js';

const logger = createLogger('CleanupExpiredWeatherCacheJob');

// Expresión cron: cada hora en el minuto 0. Cambiar a '*/30 * * * *' para pruebas.
const CRON_SCHEDULE = '0 * * * *';

/** Nombre de la colección de caché meteorológica */
const WEATHER_CACHE_COLLECTION = 'weatherCache';

/**
 * Cron job de limpieza de caché meteorológica expirada.
 *
 * @injectable
 * @dependencies MongoDBConnection
 */
@injectable()
export class CleanupExpiredWeatherCacheJob {
  private task: ScheduledTask | null = null;

  constructor(
    @inject(TYPES.MongoDBConnection) private readonly db: MongoDBConnection,
  ) {}

  /**
   * Inicia el cron job de limpieza.
   * Idempotente: llamadas adicionales no crean tareas duplicadas.
   */
  start(): void {
    if (this.task) {
      logger.warn('CleanupExpiredWeatherCacheJob ya estaba iniciado — ignorando duplicado');
      return;
    }

    this.task = schedule(CRON_SCHEDULE, async () => {
      logger.debug('CleanupExpiredWeatherCacheJob: tick — eliminando caché expirada');
      try {
        const result = await this.db.getDatabase()
          .collection(WEATHER_CACHE_COLLECTION)
          .deleteMany({ expiresAt: { $lt: new Date() } });

        if (result.deletedCount > 0) {
          logger.info(`CleanupExpiredWeatherCacheJob: ${result.deletedCount} entradas expiradas eliminadas`);
        }
      } catch (err) {
        logger.error(`CleanupExpiredWeatherCacheJob: error — ${(err as Error).message}`);
      }
    });

    logger.info(`CleanupExpiredWeatherCacheJob iniciado (schedule: "${CRON_SCHEDULE}")`);
  }

  /**
   * Detiene el cron job y libera recursos.
   */
  stop(): void {
    if (!this.task) return;
    this.task.stop();
    this.task = null;
    logger.info('CleanupExpiredWeatherCacheJob detenido');
  }
}
