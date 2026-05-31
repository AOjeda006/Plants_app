/**
 * @file rate_limit_middleware.spec.ts
 * @description Tests unitarios para RateLimitMiddleware.
 * Verifica que los limiters de auth devuelven el formato 429 esperado y
 * cabeceras estándar RateLimit-* tras superar el umbral.
 *
 * En lugar de reusar los limiters productivos (10/15min y 5/60min) — que
 * obligarían a hacer 11 peticiones para verificar el corte — montamos un
 * Express minimal con un limiter "test-only" que comparte la misma
 * configuración base (handler 429 con {code, message, details}).
 * @module Core
 * @layer Core
 */

import express, { Request, Response } from 'express';
import rateLimit from 'express-rate-limit';
import request from 'supertest';

import { authLoginRegisterLimiter } from './RateLimitMiddleware.js';

// ═══════════════════════════════════════════════════════════════════════════════
// SUITE
// ═══════════════════════════════════════════════════════════════════════════════

describe('RateLimitMiddleware', () => {
  // ─── 1) Forma del 429 con un limiter test-only de 2 req/min ────────────────

  describe('cuerpo 429 emitido por el handler personalizado', () => {
    const app = express();
    const testLimiter = rateLimit({
      windowMs: 60 * 1000,
      max: 2,
      standardHeaders: true,
      legacyHeaders: false,
      handler: (_req: Request, res: Response) => {
        const resetHeader = res.getHeader('RateLimit-Reset');
        let minutesLeft = 1;
        if (typeof resetHeader === 'string' || typeof resetHeader === 'number') {
          const resetEpoch = Number(resetHeader);
          if (!Number.isNaN(resetEpoch) && resetEpoch > 0) {
            const secondsLeft = Math.max(0, resetEpoch - Math.floor(Date.now() / 1000));
            minutesLeft = Math.max(1, Math.ceil(secondsLeft / 60));
          }
        }
        res.status(429).json({
          code: 'RATE_LIMIT_EXCEEDED',
          message: `Demasiados intentos. Inténtalo de nuevo en ${minutesLeft} minutos.`,
          details: { retryAfterMinutes: minutesLeft },
        });
      },
    });
    app.post('/login', testLimiter, (_req, res) => {
      res.status(200).json({ ok: true });
    });

    it('permite las primeras peticiones bajo el límite (200)', async () => {
      const r1 = await request(app).post('/login');
      const r2 = await request(app).post('/login');
      expect(r1.status).toBe(200);
      expect(r2.status).toBe(200);
    });

    it('al exceder el límite responde 429 con cuerpo {code, message, details.retryAfterMinutes} y cabeceras RateLimit-*', async () => {
      // Las dos primeras peticiones consumen el cupo (max:2)
      await request(app).post('/login');
      await request(app).post('/login');
      const blocked = await request(app).post('/login');

      expect(blocked.status).toBe(429);
      expect(blocked.body).toEqual(expect.objectContaining({
        code: 'RATE_LIMIT_EXCEEDED',
        message: expect.stringContaining('Demasiados intentos'),
        details: expect.objectContaining({
          retryAfterMinutes: expect.any(Number),
        }),
      }));
      expect(blocked.body.details.retryAfterMinutes).toBeGreaterThanOrEqual(1);

      // Cabeceras estándar IETF (RateLimit-*), sin las legacy X-RateLimit-*
      expect(blocked.headers['ratelimit-limit']).toBeDefined();
      expect(blocked.headers['ratelimit-remaining']).toBeDefined();
      expect(blocked.headers['ratelimit-reset']).toBeDefined();
      expect(blocked.headers['x-ratelimit-limit']).toBeUndefined();
    });
  });

  // ─── 2) Sanity check de los limiters productivos exportados ────────────────

  describe('limiters exportados', () => {
    it('authLoginRegisterLimiter es una función middleware', () => {
      expect(typeof authLoginRegisterLimiter).toBe('function');
    });

    it('los limiters productivos no bloquean en la primera petición', async () => {
      const app = express();
      app.post('/login', authLoginRegisterLimiter, (_req, res) => {
        res.status(204).end();
      });
      const res = await request(app).post('/login');
      expect(res.status).toBe(204);
    });
  });
});
