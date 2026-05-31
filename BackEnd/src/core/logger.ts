/**
 * @file logger.ts
 * @description Factoría de loggers Winston centralizados.
 * Todos los módulos deben usar createLogger() en lugar de console.log.
 * @module Core
 * @layer Core
 */

import { createLogger as winstonCreateLogger, format, transports, Logger } from 'winston';
import { opsConfig } from './config/ops.config.js';

const { combine, timestamp, printf, colorize, errors } = format;

/** Formato legible para desarrollo */
const devFormat = combine(
  colorize(),
  timestamp({ format: 'HH:mm:ss' }),
  errors({ stack: true }),
  printf(({ level, message, timestamp: ts, context, stack }) => {
    const ctx = context ? `[${context}] ` : '';
    return `${ts} ${level} ${ctx}${stack ?? message}`;
  }),
);

/** Formato JSON para producción (compatible con agregadores de logs) */
const prodFormat = combine(
  timestamp(),
  errors({ stack: true }),
  format.json(),
);

/**
 * Crea un logger Winston con el contexto indicado.
 * El nivel de log se toma de la variable de entorno LOG_LEVEL.
 *
 * @param context — Nombre del módulo o clase que usa el logger.
 * @returns {Logger} Instancia de logger Winston.
 */
export function createLogger(context: string): Logger {
  return winstonCreateLogger({
    level: process.env.LOG_LEVEL ?? 'debug',
    defaultMeta: { context },
    format: opsConfig.NODE_ENV === 'production' ? prodFormat : devFormat,
    transports: [
      new transports.Console(),
    ],
  });
}
