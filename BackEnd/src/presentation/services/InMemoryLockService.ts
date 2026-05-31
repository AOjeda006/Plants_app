/**
 * @file InMemoryLockService.ts
 * @description Implementación en memoria del servicio de bloqueo.
 * Válida únicamente para entornos single-instance (TFG, desarrollo local).
 * En producción multi-instancia debe sustituirse por RedisLockService.
 * @module Core
 * @layer Presentation
 *
 * @implements {ILockService}
 * @injectable
 */

import { injectable } from 'inversify';
import { ILockService } from './LockService.js';
import { createLogger } from '../../core/logger.js';

const logger = createLogger('InMemoryLockService');

/**
 * Lock distribuido en memoria usando un Map<key, expiresAt>.
 *
 * [⚠ TFG]: Válido solo en single-instance. No usar en producción multi-instancia.
 *
 * @implements {ILockService}
 * @injectable
 */
@injectable()
export class InMemoryLockService implements ILockService {
  /**
   * Mapa de locks activos: key → timestamp de expiración (ms desde epoch).
   * @private
   */
  private readonly locks = new Map<string, number>();

  /**
   * Intenta adquirir el lock. Si ya existe y no ha expirado, devuelve false.
   * Si ha expirado, lo sobrescribe y devuelve true.
   *
   * @param key — Clave del lock.
   * @param ttlMs — Tiempo de vida en milisegundos.
   * @returns true si el lock fue adquirido.
   */
  async acquireLock(key: string, ttlMs: number): Promise<boolean> {
    const now = Date.now();
    const expiresAt = this.locks.get(key);

    if (expiresAt && expiresAt > now) {
      logger.debug(`Lock '${key}' ya está en uso (expira en ${expiresAt - now}ms)`);
      return false;
    }

    this.locks.set(key, now + ttlMs);
    logger.debug(`Lock '${key}' adquirido (TTL: ${ttlMs}ms)`);
    return true;
  }

  /**
   * Libera el lock asociado a la clave.
   *
   * @param key — Clave del lock a liberar.
   */
  async releaseLock(key: string): Promise<void> {
    this.locks.delete(key);
    logger.debug(`Lock '${key}' liberado`);
  }
}
