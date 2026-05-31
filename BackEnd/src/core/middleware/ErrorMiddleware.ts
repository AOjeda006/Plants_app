/**
 * @file ErrorMiddleware.ts
 * @description Middleware de manejo global de errores Express.
 * Captura cualquier excepción lanzada en los controladores y la formatea
 * como { code, message, details } con el statusCode HTTP correspondiente.
 * @module Core
 * @layer Core
 */

import { Request, Response, NextFunction } from 'express';
import { HttpException } from '../exceptions/HttpException.js';
import { createLogger } from '../logger.js';

const logger = createLogger('ErrorMiddleware');

/**
 * Manejador de errores global. Debe registrarse como último middleware en Express.
 * Signature de 4 parámetros requerida por Express para detectarlo como error handler.
 *
 * @param err — Error capturado.
 * @param req — Petición HTTP.
 * @param res — Respuesta HTTP.
 * @param _next — Siguiente middleware (no se usa pero es obligatorio en la firma).
 */
export function errorMiddleware(
  err: Error,
  req: Request,
  res: Response,
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  _next: NextFunction,
): void {
  if (err instanceof HttpException) {
    logger.warn(`[${req.method}] ${req.path} → ${err.statusCode} ${err.code}: ${err.message}`);
    res.status(err.statusCode).json({
      code: err.code,
      message: err.message,
      details: err.details ?? null,
    });
  } else {
    // Error inesperado: no exponer detalles internos al cliente
    logger.error(`Error no controlado en [${req.method}] ${req.path}: ${err.message}`, { stack: err.stack });
    res.status(500).json({
      code: 'INTERNAL_SERVER_ERROR',
      message: 'Ha ocurrido un error interno. Por favor, inténtalo de nuevo.',
      details: null,
    });
  }
}
