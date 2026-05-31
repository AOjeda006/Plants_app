/**
 * @file main.ts
 * @description Punto de entrada de la aplicación backend.
 * bootstrap() inicializa el container DI, conecta a MongoDB, aplica middlewares
 * de seguridad, registra endpoints de salud y arranca el servidor HTTP.
 * @module Core
 * @layer Presentation
 */

import 'reflect-metadata';
import 'dotenv/config';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module.js';
import { configureContainer } from './core/container.js';
import { MongoDBConnection } from './data/datasources/mongodb/MongoDBConnection.js';
import { TYPES } from './core/types.js';
import { configureSecurity } from './core/middleware/SecurityMiddleware.js';
import { loggerMiddleware } from './core/middleware/LoggerMiddleware.js';
import { sanitizationMiddleware } from './core/middleware/SanitizationMiddleware.js';
import { errorMiddleware } from './core/middleware/ErrorMiddleware.js';
import { opsConfig } from './core/config/ops.config.js';
import { weatherConfig } from './core/config/weather.config.js';
import { firebaseConfig } from './core/config/firebase.config.js';
import { createLogger } from './core/logger.js';
import { AuthController } from './presentation/controllers/AuthController.js';
import { PlantController } from './presentation/controllers/PlantController.js';
import { SpeciesController } from './presentation/controllers/SpeciesController.js';
import { UploadController } from './presentation/controllers/UploadController.js';
import { WeatherController } from './presentation/controllers/WeatherController.js';
import { ReminderController } from './presentation/controllers/ReminderController.js';
import { PostController } from './presentation/controllers/PostController.js';
import { ChatController } from './presentation/controllers/ChatController.js';
import { UserController } from './presentation/controllers/UserController.js';
import { AdminController } from './presentation/controllers/AdminController.js';
import { LocationController } from './presentation/controllers/LocationController.js';
import { NotificationController } from './presentation/controllers/NotificationController.js';
import { ReportController } from './presentation/controllers/ReportController.js';
import { SocketService } from './presentation/services/SocketService.js';
import { SocketGateway } from './presentation/gateways/SocketGateway.js';
import { ReminderCronJob } from './presentation/jobs/ReminderCronJob.js';
import { CleanupExpiredWeatherCacheJob } from './presentation/jobs/CleanupExpiredWeatherCacheJob.js';
import { PurgeSoftDeletedJob } from './presentation/jobs/PurgeSoftDeletedJob.js';
import { createAuthMiddleware } from './core/middleware/AuthMiddleware.js';
import { createBanMiddleware } from './core/middleware/BanMiddleware.js';
import { JwtService } from './presentation/services/JwtService.js';
import type { Request, Response } from 'express';

const logger = createLogger('Bootstrap');

/**
 * Registra los endpoints de salud y diagnóstico.
 * - GET /health  → check enriquecido con uptime, versión y estado de
 *                  dependencias críticas (mongodb, weatherApi, fcm,
 *                  lastCronRun).
 * - GET /ready   → check de conectividad con MongoDB.
 *
 * Estado global devuelto por /health:
 *   - "ok"        → mongodb up.
 *   - "degraded"  → mongodb up pero alguna dependencia secundaria falla.
 *   - "down"      → mongodb falla. HTTP 503.
 *
 * El check de FCM (firebaseConfig.enabled) refleja únicamente si la
 * env var FCM_SERVICE_ACCOUNT_JSON está configurada y se ha podido
 * parsear. No prueba envío real (eso requiere un fcmToken válido). En
 * modo "mock" la app funciona pero los push reales no se envían.
 *
 * Rendimiento esperado del endpoint:
 *  - mongodb ping:   < 1 s en caliente.
 *  - lastCronRun:    < 50 ms (índice {cachedAt:-1} en weather_cache).
 *  - weatherApi/fcm: en memoria (sin I/O externa); responden inmediato.
 *
 * Cold start de Render Free Tier: la primera llamada después de >15 min
 * de inactividad incluye el tiempo de spin-up del contenedor (~40-60 s).
 * No es un bug del endpoint — es una característica del tier gratuito. El
 * frontend (SplashPage + ApiClient con timeouts 60 s) tolera ese rango.
 * cron-job.org pinga /health a las 23:52 Europe/Madrid para garantizar
 * que el cron de las 00:00 ya esté caliente.
 *
 * Headers anti-cache: `Cache-Control: no-cache, no-store, max-age=0`
 * para evitar que proxies intermedios (Render edge, CDN, navegador)
 * sirvan respuestas obsoletas — el estado de salud debe medirse en
 * tiempo real.
 *
 * @param app — Instancia de la aplicación NestJS.
 * @param mongoConnection — Conexión a MongoDB para el readiness check.
 * @private
 */
function registerHealthEndpoints(
  app: { getHttpAdapter: () => { get: (path: string, handler: (req: Request, res: Response) => void) => void } },
  mongoConnection: MongoDBConnection,
): void {
  const adapter = app.getHttpAdapter();

  // Versión del paquete (cargada una sola vez al arranque).
  // require permite leer JSON sin conflictos con la resolución ESM de TS.
  // eslint-disable-next-line @typescript-eslint/no-var-requires
  const pkgVersion: string = (require('../package.json') as { version: string }).version;

  /** Lee el último timestamp del cron desde la colección weather_cache. */
  async function getLastCronRun(): Promise<string | null> {
    try {
      const db = mongoConnection.getDatabase();
      const doc = await db.collection('weather_cache')
        .find({}, { projection: { cachedAt: 1 } })
        .sort({ cachedAt: -1 })
        .limit(1)
        .next();
      const ts = doc?.['cachedAt'];
      return ts instanceof Date ? ts.toISOString() : null;
    } catch {
      return null;
    }
  }

  // Liveness + readiness enriquecido en /health
  adapter.get('/health', async (_req: Request, res: Response) => {
    // mongodb: ping con medición de latencia
    let mongoStatus: 'ok' | 'down' = 'ok';
    let mongoLatency = 0;
    try {
      const t0 = Date.now();
      await mongoConnection.getDatabase().command({ ping: 1 });
      mongoLatency = Date.now() - t0;
    } catch {
      mongoStatus = 'down';
    }

    const lastCronRun = await getLastCronRun();
    const weatherApiStatus: 'ok' | 'mock' = weatherConfig.MOCK_WEATHER_MODE ? 'mock' : 'ok';

    // FCM: 'ok' si firebaseConfig.enabled (credencial cargada y parseada
    // sin errores); 'mock' en cualquier otro caso. Permite verificar
    // operacionalmente si Firebase Cloud Messaging está activo.
    const fcmStatus: 'ok' | 'mock' = firebaseConfig.enabled ? 'ok' : 'mock';

    // Estado global: down si mongo falla; ok en cualquier otro caso (sin
    // dependencias críticas adicionales en la configuración actual). El
    // estado 'mock' de weatherApi/fcm no degrada el servicio: la app
    // funciona, solo en modo simulado.
    const globalStatus: 'ok' | 'degraded' | 'down' =
      mongoStatus === 'down' ? 'down' : 'ok';

    const httpStatus = globalStatus === 'down' ? 503 : 200;

    // Anti-cache para garantizar mediciones en tiempo real.
    res.set('Cache-Control', 'no-cache, no-store, max-age=0');
    res.set('Pragma', 'no-cache');
    res.set('Expires', '0');

    res.status(httpStatus).json({
      status:    globalStatus,
      timestamp: new Date().toISOString(),
      uptime:    Math.round(process.uptime()),
      version:   pkgVersion,
      checks: {
        mongodb:    { status: mongoStatus, latencyMs: mongoLatency },
        weatherApi: { status: weatherApiStatus },
        fcm:        { status: fcmStatus },
        lastCronRun,
      },
    });
  });

  // Readiness: MongoDB responde
  adapter.get('/ready', async (_req: Request, res: Response) => {
    res.set('Cache-Control', 'no-cache, no-store, max-age=0');
    try {
      await mongoConnection.getDatabase().command({ ping: 1 });
      res.status(200).json({ status: 'ready', db: 'connected' });
    } catch {
      res.status(503).json({ status: 'not ready', db: 'disconnected' });
    }
  });
}

/**
 * Inicializa y arranca la aplicación.
 * Orden: container DI → MongoDB → NestJS app → middlewares → health → listen.
 */
async function bootstrap(): Promise<void> {
  logger.info('Iniciando aplicación TFG Plants...');

  // 1. Inicializar el contenedor de inyección de dependencias
  const container = await configureContainer({
    isProduction: opsConfig.NODE_ENV === 'production',
  });

  // 2. Conectar a MongoDB y crear índices
  const mongoConnection = container.get<MongoDBConnection>(TYPES.MongoDBConnection);
  await mongoConnection.connect();
  await mongoConnection.ensureIndexes();

  // 3. Crear la aplicación NestJS
  const app = await NestFactory.create(AppModule, {
    // Desactivar logger de NestJS en favor de Winston
    logger: opsConfig.NODE_ENV === 'production' ? ['error', 'warn'] : ['log', 'error', 'warn', 'debug'],
    bufferLogs: false,
  });

  // 4. Obtener la instancia Express subyacente y aplicar middlewares
  const expressApp = app.getHttpAdapter().getInstance();
  configureSecurity(expressApp);
  expressApp.use(loggerMiddleware);
  expressApp.use(sanitizationMiddleware);

  // 5. Límite de tamaño de body (payload)
  app.use(require('express').json({ limit: opsConfig.PAYLOAD_SIZE_LIMIT }));
  app.use(require('express').urlencoded({ extended: true, limit: opsConfig.PAYLOAD_SIZE_LIMIT }));

  // 6. Registrar rutas de la API
  const authController      = container.get<AuthController>(TYPES.AuthController);
  const plantController     = container.get<PlantController>(TYPES.PlantController);
  const speciesController   = container.get<SpeciesController>(TYPES.SpeciesController);
  const uploadController    = container.get<UploadController>(TYPES.UploadController);
  const weatherController   = container.get<WeatherController>(TYPES.WeatherController);
  const reminderController  = container.get<ReminderController>(TYPES.ReminderController);
  const postController      = container.get<PostController>(TYPES.PostController);
  const chatController      = container.get<ChatController>(TYPES.ChatController);
  const userController      = container.get<UserController>(TYPES.UserController);
  const adminController     = container.get<AdminController>(TYPES.AdminController);
  const locationController      = container.get<LocationController>(TYPES.LocationController);
  const notificationController  = container.get<NotificationController>(TYPES.NotificationController);
  const reportController        = container.get<ReportController>(TYPES.ReportController);

  // Middleware de autenticación para rutas protegidas
  const jwtService   = container.get<JwtService>(TYPES.JwtService);
  const requireAuth  = createAuthMiddleware(jwtService);
  // Middleware de verificación de baneo (bloquea escritura si bannedUntil > now).
  const checkBan     = createBanMiddleware(mongoConnection);

  // El router de auth recibe `requireAuth` para proteger
  // POST /auth/refresh (única ruta autenticada en /auth/...).
  expressApp.use('/auth',      authController.router(requireAuth));
  expressApp.use('/plants',    requireAuth, plantController.router());
  expressApp.use('/species',   requireAuth, speciesController.router());
  expressApp.use('/upload',    requireAuth, uploadController.router());
  expressApp.use('/weather',   requireAuth, weatherController.router());
  expressApp.use('/reminders', requireAuth, reminderController.router());
  expressApp.use('/community', requireAuth, checkBan, postController.router());
  expressApp.use('/chat',      requireAuth, checkBan, chatController.router());
  expressApp.use('/users',     requireAuth, userController.router());
  expressApp.use('/admin',     requireAuth, adminController.router());
  expressApp.use('/locations',     requireAuth, locationController.router());
  expressApp.use('/notifications', requireAuth, notificationController.router());
  expressApp.use('/reports',       requireAuth, reportController.router());

  // 7. Registrar endpoints de salud
  registerHealthEndpoints(app as never, mongoConnection);

  // 8. Middleware de errores (debe ir al final)
  expressApp.use(errorMiddleware);

  // 9. Arrancar el servidor HTTP (host 0.0.0.0 obligatorio para Render/contenedores)
  await app.listen(opsConfig.PORT, '0.0.0.0');
  logger.info(`Servidor escuchando en 0.0.0.0:${opsConfig.PORT}`);
  logger.info(`Health: /health`);
  logger.info(`Ready:  /ready`);

  // 10. Inicializar Socket.IO (debe hacerse después de app.listen())
  const socketService = container.get<SocketService>(TYPES.SocketService);
  const httpServer    = app.getHttpServer() as import('http').Server;
  socketService.init(httpServer);

  const socketGateway = container.get<SocketGateway>(SocketGateway);
  socketGateway.init();
  logger.info('Socket.IO inicializado y gateway activo');

  // 11. Iniciar cron jobs
  const reminderCronJob               = container.get<ReminderCronJob>(ReminderCronJob);
  const cleanupExpiredWeatherCacheJob = container.get<CleanupExpiredWeatherCacheJob>(CleanupExpiredWeatherCacheJob);
  const purgeSoftDeletedJob           = container.get<PurgeSoftDeletedJob>(PurgeSoftDeletedJob);
  reminderCronJob.start();
  cleanupExpiredWeatherCacheJob.start();
  purgeSoftDeletedJob.start();
}

bootstrap().catch((err: Error) => {
  logger.error(`Error fatal en bootstrap: ${err.message}`, { stack: err.stack });
  process.exit(1);
});
