/**
 * @file SecurityMiddleware.ts
 * @description Configuración centralizada de seguridad HTTP:
 * helmet, CORS abierto (TFG), rate limiting, compresión y límites de body.
 * @module Core
 * @layer Core
 */

import { Application } from 'express';
import helmet from 'helmet';
import cors from 'cors';
import rateLimit from 'express-rate-limit';
import compression from 'compression';
import { opsConfig } from '../config/ops.config.js';

/**
 * Aplica todos los middlewares de seguridad a la aplicación Express.
 * Debe llamarse en bootstrap() antes de registrar las rutas.
 *
 * @param app — Instancia de la aplicación Express/NestJS.
 */
export function configureSecurity(app: Application): void {
  // Render mete su proxy delante (X-Forwarded-For). Sin 'trust proxy'
  // express-rate-limit registra todas las peticiones con la IP interna del
  // proxy (127.0.0.1) y lanza ERR_ERL_UNEXPECTED_X_FORWARDED_FOR en cada
  // request. `1` = confiar en un único hop (Render/Vercel/Heroku/etc);
  // req.ip pasa a ser la IP real del cliente y el rate limit funciona por
  // usuario, no por proxy.
  app.set('trust proxy', 1);

  // Cabeceras de seguridad HTTP (XSS, clickjacking, MIME sniffing, etc.)
  app.use(helmet());

  // TFG: CORS refleja cualquier origen. Prototipo con usuarios controlados,
  // no producción; simplifica el despliegue en Render sin configuración extra.
  app.use(
    cors({
      origin: true,
      credentials: true,
      methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
      allowedHeaders: ['Content-Type', 'Authorization'],
    }),
  );

  // Rate limiting: limitar peticiones por IP para prevenir abuso
  app.use(
    rateLimit({
      windowMs: opsConfig.RATE_LIMIT_WINDOW_MS,
      max: opsConfig.RATE_LIMIT_MAX,
      standardHeaders: true,
      legacyHeaders: false,
      message: {
        code: 'RATE_LIMIT_EXCEEDED',
        message: 'Demasiadas peticiones. Por favor, espera un momento.',
        details: null,
      },
    }),
  );

  // Compresión gzip/brotli de respuestas
  app.use(compression());
}
