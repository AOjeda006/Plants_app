/**
 * @file IProcessPendingRemindersUseCase.ts
 * @description Interfaz del caso de uso para procesar recordatorios pendientes (cron job).
 * Encapsula lock de idempotencia y procesamiento de la cola de recordatorios vencidos.
 * @module Reminders
 * @layer Domain
 */

/**
 * Resumen diagnóstico de una ejecución del cron.
 * Usado por POST /admin/run-cron para mostrar al admin por qué no se crearon
 * notificaciones (plantas filtradas, idempotencia, días no-1/15, etc.).
 */
export interface CronRunSummary {
  skipped:          boolean;                   // true si no se adquirió el lock
  pendingReminders: number;                    // reminders en cola (scheduledDate<=now)
  created:          {                          // notificaciones creadas por subproceso
    reminders:     number;
    weather:       number;
    yesterdayRain: number;
    pruning:       number;
    harvest:       number;
    allClear:      number;
    total:         number;
  };
  diagnostics: string[];                        // razones de skip (idempotencia, filtro día, filtro exterior, etc.)
}

export interface IProcessPendingRemindersUseCase {
  execute(): Promise<CronRunSummary>;
}
