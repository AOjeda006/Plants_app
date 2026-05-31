/**
 * @file ops.config.ts
 * @description Configuración operacional: rate limiting, tamaño de payload, métricas y Redis.
 * @module Core
 * @layer Core
 */

import 'dotenv/config';

/**
 * Configuración operacional cargada desde variables de entorno.
 */
export const opsConfig = {
  /** Ventana de tiempo en ms para el rate limiter */
  RATE_LIMIT_WINDOW_MS: parseInt(process.env.RATE_LIMIT_WINDOW_MS ?? '60000', 10),

  /** Número máximo de peticiones por ventana por IP */
  RATE_LIMIT_MAX: parseInt(process.env.RATE_LIMIT_MAX ?? '100', 10),

  /** Tamaño máximo del body de las peticiones */
  PAYLOAD_SIZE_LIMIT: process.env.PAYLOAD_SIZE_LIMIT ?? '10mb',

  /** Habilitar endpoint de métricas Prometheus (/metrics) */
  METRICS_ENABLED: process.env.METRICS_ENABLED === 'true',

  /**
   * URL de Redis para LockService distribuido.
   * Si no está definida, se usa InMemoryLockService como fallback.
   * TFG: sin Redis, InMemoryLockService es suficiente para entorno single-instance.
   */
  REDIS_URL: process.env.REDIS_URL ?? null,

  /** Puerto del servidor HTTP */
  PORT: parseInt(process.env.PORT ?? '3000', 10),

  /** Entorno de ejecución */
  NODE_ENV: process.env.NODE_ENV ?? 'development',
} as const;
