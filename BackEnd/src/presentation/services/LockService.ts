/**
 * @file LockService.ts
 * @description Interfaz del servicio de bloqueo distribuido.
 * Utilizado por ProcessPendingRemindersUseCase para garantizar que el cron job
 * no se ejecute simultáneamente en múltiples instancias.
 * @module Core
 * @layer Presentation
 */

/**
 * Interfaz de bloqueo distribuido.
 * Implementaciones: InMemoryLockService (TFG/desarrollo), RedisLockService (producción).
 */
export interface ILockService {
  /**
   * Intenta adquirir un lock exclusivo para la clave dada.
   *
   * @param key — Identificador único del lock (ej: 'reminder-cron').
   * @param ttlMs — Tiempo de vida del lock en milisegundos.
   * @returns true si el lock fue adquirido, false si ya estaba en uso.
   */
  acquireLock(key: string, ttlMs: number): Promise<boolean>;

  /**
   * Libera el lock asociado a la clave.
   *
   * @param key — Identificador del lock a liberar.
   */
  releaseLock(key: string): Promise<void>;
}
