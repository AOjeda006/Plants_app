/**
 * @file PurgeSoftDeletedJob.ts
 * @description Cron job para purgar físicamente los registros eliminados lógicamente
 * (soft-deleted) que superen el período de retención (30 días por defecto).
 * Afecta a colecciones: users, plants, posts, comments.
 * TFG: frecuencia diaria a las 03:00 para no interferir con el uso normal.
 * @module User
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

const logger = createLogger('PurgeSoftDeletedJob');

/** Expresión cron: cada día a las 03:00 UTC */
const CRON_SCHEDULE = '0 3 * * *';

/** Días de retención antes de purga física */
const RETENTION_DAYS = 30;

/** Colecciones que tienen soft-delete (campo deletedAt) */
const SOFT_DELETE_COLLECTIONS = ['users', 'plants', 'posts', 'comments'];

/**
 * Cron job de purga física de registros con soft-delete expirados.
 *
 * @injectable
 * @dependencies MongoDBConnection
 */
@injectable()
export class PurgeSoftDeletedJob {
  private task: ScheduledTask | null = null;

  constructor(
    @inject(TYPES.MongoDBConnection) private readonly db: MongoDBConnection,
  ) {}

  /**
   * Inicia el cron job de purga.
   * Idempotente: llamadas adicionales no crean tareas duplicadas.
   */
  start(): void {
    if (this.task) {
      logger.warn('PurgeSoftDeletedJob ya estaba iniciado — ignorando duplicado');
      return;
    }

    this.task = schedule(CRON_SCHEDULE, async () => {
      logger.debug('PurgeSoftDeletedJob: tick — purgando registros expirados');
      const cutoff = new Date(Date.now() - RETENTION_DAYS * 24 * 60 * 60 * 1000);

      let totalPurged = 0;
      for (const collectionName of SOFT_DELETE_COLLECTIONS) {
        try {
          const result = await this.db.getDatabase()
            .collection(collectionName)
            .deleteMany({ deletedAt: { $lt: cutoff } });

          if (result.deletedCount > 0) {
            logger.info(`PurgeSoftDeletedJob: ${result.deletedCount} registros purgados en '${collectionName}'`);
            totalPurged += result.deletedCount;
          }
        } catch (err) {
          // No detener el proceso por un error en una colección — continuar con las demás
          logger.error(`PurgeSoftDeletedJob: error en '${collectionName}' — ${(err as Error).message}`);
        }
      }

      if (totalPurged > 0) {
        logger.info(`PurgeSoftDeletedJob: purga completada — ${totalPurged} registros eliminados en total`);
      }
    });

    logger.info(`PurgeSoftDeletedJob iniciado (schedule: "${CRON_SCHEDULE}", retención: ${RETENTION_DAYS} días)`);
  }

  /**
   * Detiene el cron job y libera recursos.
   */
  stop(): void {
    if (!this.task) return;
    this.task.stop();
    this.task = null;
    logger.info('PurgeSoftDeletedJob detenido');
  }
}
