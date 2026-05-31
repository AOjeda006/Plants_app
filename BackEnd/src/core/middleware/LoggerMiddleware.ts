/**
 * @file LoggerMiddleware.ts
 * @description Middleware de logging de peticiones HTTP con requestId único,
 * duración de la respuesta y enmascaramiento de datos sensibles (PII).
 * @module Core
 * @layer Core
 */

import { Request, Response, NextFunction } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { createLogger } from '../logger.js';

const logger = createLogger('HTTP');

/** Campos cuyo valor completo debe sustituirse por '***' en los logs */
const SENSITIVE_FIELDS = [
  'password', 'passwordhash', 'newpassword', 'currentpassword',
  'token', 'accesstoken', 'refreshtoken', 'fcmtoken',
  'authorization', 'cookie', 'secret', 'apikey',
];

/** Campos de email — se enmascaran parcialmente: a***@dominio.com */
const EMAIL_FIELDS = ['email', 'emailaddress'];

/**
 * Enmascara un email parcialmente para logs: muestra solo el primer carácter.
 * Ejemplo: "usuario@example.com" → "u***@example.com".
 *
 * @param email — Dirección de correo electrónico.
 * @returns Email enmascarado.
 * @private
 */
function maskEmail(email: string): string {
  const parts = email.split('@');
  if (parts.length !== 2 || parts[0].length === 0) return '***@***';
  return `${parts[0].charAt(0)}***@${parts[1]}`;
}

/**
 * Enmascara recursivamente los valores de campos sensibles en un objeto para
 * evitar que aparezcan en los logs (protección de PII / RGPD).
 * Soporta objetos anidados y arrays.
 *
 * @param obj — Objeto a enmascarar.
 * @returns Copia profunda del objeto con valores sensibles enmascarados.
 * @private
 */
function maskSensitiveFields(obj: Record<string, unknown>): Record<string, unknown> {
  const masked: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(obj)) {
    const lowerKey = key.toLowerCase();
    if (SENSITIVE_FIELDS.includes(lowerKey)) {
      masked[key] = '***';
    } else if (EMAIL_FIELDS.includes(lowerKey) && typeof value === 'string') {
      masked[key] = maskEmail(value);
    } else if (Array.isArray(value)) {
      masked[key] = value.map((item) =>
        typeof item === 'object' && item !== null
          ? maskSensitiveFields(item as Record<string, unknown>)
          : item,
      );
    } else if (typeof value === 'object' && value !== null) {
      masked[key] = maskSensitiveFields(value as Record<string, unknown>);
    } else {
      masked[key] = value;
    }
  }
  return masked;
}

/**
 * Middleware de logging HTTP. Registra método, ruta, requestId, IP, status y duración.
 * Enmascara query params Y body de la petición para proteger PII (RGPD).
 * El requestId se adjunta a la petición para trazabilidad en logs de controladores.
 */
export function loggerMiddleware(req: Request, res: Response, next: NextFunction): void {
  const requestId = uuidv4();
  const start = Date.now();

  // Adjuntar requestId al objeto req para uso en controladores y otros middlewares
  (req as Request & { requestId: string }).requestId = requestId;

  const safeQuery = maskSensitiveFields(req.query as Record<string, unknown>);

  // Enmascarar body solo en métodos que lo envían (POST, PUT, PATCH)
  const safeBody =
    req.body && typeof req.body === 'object' && Object.keys(req.body as object).length > 0
      ? maskSensitiveFields(req.body as Record<string, unknown>)
      : undefined;

  res.on('finish', () => {
    const duration = Date.now() - start;
    logger.info(`[${requestId}] ${req.method} ${req.path} → ${res.statusCode} (${duration}ms)`, {
      ip:        req.ip,
      query:     Object.keys(safeQuery).length > 0 ? safeQuery : undefined,
      body:      safeBody,
      userAgent: req.headers['user-agent'],
    });
  });

  next();
}
