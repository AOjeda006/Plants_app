/**
 * @file RateLimitMiddleware.ts
 * @description Middlewares de rate limiting específicos para endpoints sensibles
 * (autenticación) que deben mitigarse contra ataques de fuerza bruta.
 * El rate limit global (más laxo) está en SecurityMiddleware.
 * @module Core
 * @layer Core
 */

import rateLimit, { Options, RateLimitRequestHandler } from 'express-rate-limit';
import type { Request, Response } from 'express';

/**
 * Construye un mensaje 429 con minutos restantes calculados a partir de la
 * cabecera estándar `RateLimit-Reset` (segundos desde epoch).
 *
 * @param req — request entrante
 * @param res — response (con cabeceras Rate-Limit-* ya escritas por la lib)
 * @returns objeto JSON con `code`, `message` y `details`
 */
function buildLimitMessage(req: Request, res: Response): {
  code: string; message: string; details: { retryAfterMinutes: number } | null;
} {
  const resetHeader = res.getHeader('RateLimit-Reset');
  let minutesLeft = 1;
  if (typeof resetHeader === 'string' || typeof resetHeader === 'number') {
    const resetEpoch = Number(resetHeader);
    if (!Number.isNaN(resetEpoch) && resetEpoch > 0) {
      const secondsLeft = Math.max(0, resetEpoch - Math.floor(Date.now() / 1000));
      minutesLeft = Math.max(1, Math.ceil(secondsLeft / 60));
    }
  }
  return {
    code: 'RATE_LIMIT_EXCEEDED',
    message: `Demasiados intentos. Inténtalo de nuevo en ${minutesLeft} minutos.`,
    details: { retryAfterMinutes: minutesLeft },
  };
}

const baseOptions: Partial<Options> = {
  standardHeaders: true,   // RateLimit-* (estándar IETF)
  legacyHeaders:   false,  // sin X-RateLimit-*
  // El handler personalizado garantiza el formato {code, message, details}
  handler: (req, res) => {
    res.status(429).json(buildLimitMessage(req, res));
  },
};

/**
 * Limitador para `/auth/login` y `/auth/register`.
 * 10 intentos por IP cada 15 minutos. Mitiga fuerza bruta y enumeración de
 * cuentas sin penalizar al usuario legítimo que se equivoca puntualmente.
 */
export const authLoginRegisterLimiter: RateLimitRequestHandler = rateLimit({
  ...baseOptions,
  windowMs: 15 * 60 * 1000,
  max: 10,
});
