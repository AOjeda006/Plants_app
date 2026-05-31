/**
 * @file ProcessPendingRemindersUseCase.ts
 * @description Caso de uso para procesar los recordatorios pendientes desde el cron job.
 * Flujo (00:00 diario):
 *   1. Adquirir lock distribuido ('reminder-cron') para evitar ejecuciones paralelas.
 *   2. Procesar recordatorios pendientes (scheduledDate <= ahora).
 *   3. Procesar alertas de clima (lluvia/tormenta) para plantas con ubicación.
 *   4. Procesar notificaciones de poda (días 1 y 15 del mes de poda).
 *   5. Procesar notificaciones de cosecha (días 1 y 15 del mes de cosecha).
 * @module Reminders
 * @layer Domain
 *
 * @implements {IProcessPendingRemindersUseCase}
 * @injectable
 * @dependencies IReminderRepository, IReminderHistoryRepository, IUserRepository,
 *              INotificationRepository, IPlantSpeciesRepository, IPlantRepository,
 *              WeatherAPIDataSource, NotificationService, ILockService
 */

import { injectable, inject } from 'inversify';
import { TYPES } from '../../../core/types.js';
import type { IProcessPendingRemindersUseCase, CronRunSummary } from '../../interfaces/usecases/reminders/IProcessPendingRemindersUseCase.js';
import type { IReminderRepository } from '../../repositories/IReminderRepository.js';
import type { IReminderHistoryRepository } from '../../repositories/IReminderHistoryRepository.js';
import type { IUserRepository } from '../../repositories/IUserRepository.js';
import type { INotificationRepository } from '../../repositories/INotificationRepository.js';
import type { IPlantSpeciesRepository } from '../../repositories/IPlantSpeciesRepository.js';
import type { IPlantRepository } from '../../repositories/IPlantRepository.js';
import type { Plant } from '../../entities/Plant.js';
import { WeatherAPIDataSource } from '../../../data/datasources/external/WeatherAPIDataSource.js';
import { NotificationService } from '../../../presentation/services/NotificationService.js';
import { SocketService } from '../../../presentation/services/SocketService.js';
import { NotificationMessages } from '../../../core/notifications/notification-messages.es.js';
import type { ILockService } from '../../../presentation/services/LockService.js';
import { createLogger } from '../../../core/logger.js';
import type { NotificationType } from '../../entities/Notification.js';

const logger = createLogger('ProcessPendingRemindersUseCase');

/** Número máximo de intentos antes de suspender el recordatorio */
const MAX_ATTEMPTS = 3;

/** TTL del lock del cron en milisegundos (5 minutos) */
const CRON_LOCK_TTL_MS = 5 * 60 * 1000;

/** Clave del lock distribuido para el procesamiento de recordatorios */
const CRON_LOCK_KEY = 'reminder-cron';

/** Umbral por defecto de lluvia (mm) cuando la especie no define minRainfallMm. */
const DEFAULT_MIN_RAINFALL_MM = 5;

/**
 * Calcula el factor estacional de riego para un mes dado.
 * dic–feb = invierno, jun–ago = verano. Primavera y otoño = 1.0 (sin ajuste).
 */
function getSeasonalFactor(month: number, adj?: { summer?: number; winter?: number }): number {
  if (!adj) return 1.0;
  if (month >= 6 && month <= 8)  return adj.summer ?? 1.0;
  if (month >= 12 || month <= 2) return adj.winter ?? 1.0;
  return 1.0;
}


/**
 * Procesa todos los recordatorios pendientes de forma idempotente y con lock distribuido.
 *
 * @implements {IProcessPendingRemindersUseCase}
 * @injectable
 * @dependencies IReminderRepository, IReminderHistoryRepository, IUserRepository,
 *              INotificationRepository, IPlantSpeciesRepository, IPlantRepository,
 *              WeatherAPIDataSource, NotificationService, ILockService
 */
@injectable()
export class ProcessPendingRemindersUseCase implements IProcessPendingRemindersUseCase {
  constructor(
    @inject(TYPES.IReminderRepository)        private readonly reminderRepo: IReminderRepository,
    @inject(TYPES.IReminderHistoryRepository) private readonly historyRepo: IReminderHistoryRepository,
    @inject(TYPES.IUserRepository)            private readonly userRepo: IUserRepository,
    @inject(TYPES.INotificationRepository)    private readonly notifRepo: INotificationRepository,
    @inject(TYPES.IPlantSpeciesRepository)    private readonly speciesRepo: IPlantSpeciesRepository,
    @inject(TYPES.IPlantRepository)           private readonly plantRepo: IPlantRepository,
    @inject(TYPES.WeatherDataSource)          private readonly weatherDS: WeatherAPIDataSource,
    @inject(TYPES.NotificationService)        private readonly notificationService: NotificationService,
    @inject(TYPES.SocketService)              private readonly socketService: SocketService,
    @inject(TYPES.LockService)                private readonly lockService: ILockService,
  ) {}

  /**
   * Emite `notification:new` por socket al usuario destino para que el
   * frontend (NotificationsViewModel + listener en MainTabsPage)
   * refresque la pestaña Avisos en caliente sin esperar al polling de
   * 60s. Silenciado: si el usuario no está online el emit es no-op.
   * @private
   */
  private _notifySocketUser(userId: string): void {
    try {
      this.socketService.emitToUser(userId, 'notification:new', {});
    } catch (err) {
      logger.warn(`emit notification:new failed for ${userId}: ${(err as Error).message}`);
    }
  }

  /**
   * Wrapper sobre `notifRepo.create` que además emite `notification:new`
   * por socket al usuario destino. Garantiza que el frontend refresca la
   * pestaña Avisos en caliente cada vez que el cron genera una alerta
   * (riego, poda, cosecha, lluvia, all-clear). Sin este wrapper la lista
   * solo se refrescaba al abrir manualmente la pestaña o cada 60s por
   * polling.
   * @private
   */
  private async _persistAndPushSocket(notif: {
    userId: string;
    type: NotificationType;
    message: string;
    reminderId?: string;
    plantId?: string;
    isRead: boolean;
    createdAt: Date;
  }): Promise<void> {
    await this.notifRepo.create(notif);
    this._notifySocketUser(notif.userId);
  }

  /**
   * Cola de pushes agrupados por userId. Se llena durante execute() y
   * se drena al final con _drainPushQueue. Map<userId, mensajes[]>.
   */
  private readonly _pushQueue: Map<string, string[]> = new Map();

  /**
   * Encola un mensaje para envío push agrupado. Idempotente: no enviar
   * de inmediato; el push real se hace en _drainPushQueue.
   * @private
   */
  private _enqueuePush(userId: string, message: string): void {
    const arr = this._pushQueue.get(userId) ?? [];
    arr.push(message);
    this._pushQueue.set(userId, arr);
  }

  /**
   * Drena la cola enviando 1 push FCM por usuario con el resumen.
   * - 1 mensaje  → push con ese mensaje literal.
   * - N mensajes → push con resumen "Tienes N alertas hoy".
   * Usuarios sin fcmToken o sin permisos se omiten silenciosamente.
   * @private
   */
  private async _drainPushQueue(): Promise<void> {
    if (this._pushQueue.size === 0) return;
    logger.info(`Drenando cola de pushes: ${this._pushQueue.size} usuario(s)`);
    for (const [userId, messages] of this._pushQueue.entries()) {
      const user = await this.userRepo.findById(userId).catch(() => null);
      if (!user?.canReceiveNotifications()) continue;
      const count = messages.length;
      const body  = count === 1
        ? messages[0]!
        : NotificationMessages.dailySummary.multipleAlerts(count);
      try {
        await this.notificationService.sendToUser(user.fcmToken!, {
          title:  '🌱 Plants',
          body,
          data:   { type: 'aviso', count: String(count) },
          userId,
        });
      } catch (err) {
        logger.warn(`Push agrupado fallido para userId=${userId}: ${(err as Error).message}`);
      }
    }
  }

  /**
   * Punto de entrada del cron job.
   * Adquiere el lock, procesa y libera aunque haya errores.
   * Devuelve un resumen diagnóstico con contadores por subproceso.
   */
  async execute(): Promise<CronRunSummary> {
    const summary: CronRunSummary = {
      skipped:          false,
      pendingReminders: 0,
      created:          { reminders: 0, weather: 0, yesterdayRain: 0, pruning: 0, harvest: 0, allClear: 0, total: 0 },
      diagnostics:      [],
    };

    const acquired = await this.lockService.acquireLock(CRON_LOCK_KEY, CRON_LOCK_TTL_MS);
    if (!acquired) {
      logger.warn('ProcessPendingReminders: ejecución omitida — lock ya en uso');
      summary.skipped = true;
      summary.diagnostics.push('lock_in_use');
      return summary;
    }

    // Cola de pushes agrupados por usuario. Cada sub-proceso
    // (_processWeather, _processYesterdayRain, _processPruning,
    // _processHarvest, el bucle de reminders pendientes y _processAllClear)
    // inserta sus notifs in-app en MongoDB y encola el mensaje aquí. Al
    // final del cron drenamos la cola enviando UN solo push FCM por
    // usuario con el resumen — evita spam de notificaciones individuales
    // en la barra del sistema cuando un usuario tiene muchas plantas.
    this._pushQueue.clear();

    try {
      await this._processAll(summary);
      await this._drainPushQueue();
    } finally {
      this._pushQueue.clear();
      await this.lockService.releaseLock(CRON_LOCK_KEY);
    }

    summary.created.total =
      summary.created.reminders    +
      summary.created.weather      +
      summary.created.yesterdayRain +
      summary.created.pruning      +
      summary.created.harvest      +
      summary.created.allClear;

    logger.info(
      `[CronSummary] pending=${summary.pendingReminders} ` +
      `notifs created=${summary.created.total} ` +
      `(reminders=${summary.created.reminders}, weather=${summary.created.weather}, ` +
      `yesterdayRain=${summary.created.yesterdayRain}, pruning=${summary.created.pruning}, ` +
      `harvest=${summary.created.harvest}, allClear=${summary.created.allClear}) ` +
      `diagnostics=[${summary.diagnostics.join(', ')}]`,
    );

    return summary;
  }

  /**
   * Procesa todos los recordatorios pendientes.
   * @private
   */
  private async _processAll(summary: CronRunSummary): Promise<void> {
    const pending = await this.reminderRepo.findPending();
    summary.pendingReminders = pending.length;
    logger.info(`ProcessPendingReminders: ${pending.length} recordatorio(s) pendiente(s)`);

    // Alertas de clima para plantas con ubicación (lluvia/tormenta próximas 24h).
    await this._processWeather(summary);

    // Lluvia de ayer: si llovió suficiente, considerar plantas de exterior regadas.
    await this._processYesterdayRain(summary);

    // Notificaciones de poda (días 1 y 15 del mes de poda).
    await this._processPruning(summary);

    // Notificaciones de cosecha (días 1 y 15 del mes de cosecha).
    await this._processHarvest(summary);

    // Procesar recordatorios individuales primero, luego "Todo al día".
    for (const reminder of pending) {
      const today = new Date().toISOString().slice(0, 10); // YYYY-MM-DD
      const idempotencyKey = `${reminder.id}_${today}`;

      try {
        // Evitar procesamiento duplicado (reinicios del cron durante el mismo día)
        const alreadyProcessed = await this.historyRepo.exists(idempotencyKey);
        if (alreadyProcessed) {
          logger.debug(`Recordatorio ${reminder.id} ya procesado hoy — skip`);
          continue;
        }

        // Persistir notificación in-app (siempre, independientemente del push)
        await this._persistAndPushSocket({
          userId:     reminder.userId,
          type:       reminder.type as NotificationType,
          message:    reminder.message,
          reminderId: reminder.id,
          plantId:    reminder.plantId,
          isRead:     false,
          createdAt:  new Date(),
        });
        summary.created.reminders++;

        // Encolar push para envío agrupado al final del cron.
        this._enqueuePush(reminder.userId, reminder.message);

        // Registrar éxito en historial
        await this.historyRepo.create({
          reminderId:     reminder.id,
          processedAt:    new Date(),
          result:         'success',
          idempotencyKey,
        });

        // Incrementar intentos
        const newAttempts = reminder.attempts + 1;
        const shouldSuspend = newAttempts >= MAX_ATTEMPTS;
        await this.reminderRepo.updateStatus(reminder.id, {
          attempts:  newAttempts,
          suspended: shouldSuspend,
        });

        if (shouldSuspend) {
          logger.warn(`Recordatorio ${reminder.id} suspendido tras ${newAttempts} intentos`);
        }

      } catch (err) {
        const errorMsg = (err as Error).message;
        logger.error(`Error procesando recordatorio ${reminder.id}: ${errorMsg}`);

        // Registrar fallo en historial (no relanzar para continuar con los demás)
        await this.historyRepo.create({
          reminderId:     reminder.id,
          processedAt:    new Date(),
          result:         'error',
          details:        errorMsg,
          idempotencyKey,
        }).catch((histErr) => {
          logger.error(`No se pudo registrar error en historial: ${(histErr as Error).message}`);
        });
      }
    }

    // "Todo al día": generar notificación informativa para usuarios sin alertas hoy.
    await this._processAllClear(summary);
  }

  /**
   * Genera una notificación "Todo al día" para usuarios con plantas que no
   * recibieron ninguna notificación hoy. Idempotencia: all_clear_{userId}_{YYYY-MM-DD}.
   * @private
   */
  private async _processAllClear(summary: CronRunSummary): Promise<void> {
    const today = new Date().toISOString().slice(0, 10);
    const now   = new Date();

    try {
      const userIds = await this.plantRepo.findDistinctUserIds();
      if (userIds.length === 0) {
        summary.diagnostics.push('allClear_no_users_with_plants');
        return;
      }

      logger.info(`ProcessAllClear: verificando ${userIds.length} usuario(s) con plantas`);

      let skippedIdem  = 0;
      let skippedHasNotifs = 0;

      for (const userId of userIds) {
        const allClearKey = `all_clear_${userId}_${today}`;

        // Idempotencia: no generar dos veces el mismo día.
        const alreadyProcessed = await this.historyRepo.exists(allClearKey);
        if (alreadyProcessed) { skippedIdem++; continue; }

        // Si ya recibió alguna notificación hoy, no generar "Todo al día".
        const todayCount = await this.notifRepo.countTodayByUserId(userId);
        if (todayCount > 0) { skippedHasNotifs++; continue; }

        const allClearMessage = NotificationMessages.dailySummary.allCaughtUp();
        await this._persistAndPushSocket({
          userId,
          type:      'info',
          message:   allClearMessage,
          isRead:    false,
          createdAt: now,
        });

        await this.historyRepo.create({
          reminderId:     '',
          processedAt:    now,
          result:         'success',
          idempotencyKey: allClearKey,
        });

        summary.created.allClear++;
        // Encolar push agrupado.
        this._enqueuePush(userId, allClearMessage);
        logger.debug(`Notificación "Todo al día" creada para usuario ${userId}`);
      }

      if (skippedIdem > 0)        summary.diagnostics.push(`allClear_idem=${skippedIdem}`);
      if (skippedHasNotifs > 0)   summary.diagnostics.push(`allClear_hasNotifs=${skippedHasNotifs}`);
    } catch (err) {
      logger.error(`Error en processAllClear: ${(err as Error).message}`);
    }
  }

  /**
   * Genera alertas de clima para las plantas de exterior que necesitan cuidados
   * en las próximas 48h y tienen ubicación geográfica definida.
   * - Lluvia >= 70 % en las próximas 24h → notificación "posponer riego".
   * - Tormenta en las próximas 24h → notificación de alerta.
   * Solo aplica a plantas con location === 'Exterior'.
   * Idempotencia diaria: weather_rain_{plantId}_{YYYY-MM-DD} / weather_storm_{plantId}_{YYYY-MM-DD}.
   * @private
   */
  private async _processWeather(summary: CronRunSummary): Promise<void> {
    const today = new Date().toISOString().slice(0, 10);

    // Plantas de exterior con coordenadas que necesitan atención en las próximas 48h.
    const plants = await this.plantRepo.findPlantsNeedingCare(48);
    const plantsWithLocation = plants.filter(
      (p) => p.location === 'Exterior'
          && p.plantLocationLat != null
          && p.plantLocationLon != null,
    );

    if (plantsWithLocation.length === 0) {
      summary.diagnostics.push(`weather_no_outdoor_in_48h (total_plants_in_window=${plants.length})`);
      return;
    }

    logger.info(`ProcessWeather: revisando clima para ${plantsWithLocation.length} planta(s) de exterior`);

    for (const plant of plantsWithLocation) {
      try {
        const locationKey = this.weatherDS.keyForLocation(plant.plantLocationLat!, plant.plantLocationLon!);
        const weather     = await this.weatherDS.fetchWeatherData(locationKey, 48);
        const next24h     = weather.forecast.slice(0, 24);
        const now         = new Date();

        // Probabilidad máxima de lluvia en las próximas 24h.
        const maxRain = next24h.reduce((max, h) => Math.max(max, h.rainProbability), 0);

        // Detectar condición de tormenta en las próximas 24h.
        // WeatherAPI se llama con `lang=es`, así que la condition.text
        // llega traducida ("Tormenta eléctrica", "Truenos dispersos"). El
        // regex debe contemplar tanto los términos ingleses como los
        // españoles para que el matching funcione en producción.
        const stormHour = next24h.find((h) => /storm|thunder|tormenta|trueno/i.test(h.condition));

        // Notificación de lluvia (sugerir posponer riego).
        if (maxRain >= 70) {
          const rainKey = `weather_rain_${plant.id}_${today}`;
          if (!(await this.historyRepo.exists(rainKey))) {
            // Si se pospone el riego por lluvia prevista, reseteamos
            // nextWatering Y guardamos pendingRainAdjustment con
            // previousNextWatering para poder hacer rollback al día
            // siguiente si la lluvia no se confirma vía history. Si la
            // planta YA tiene un pendingRainAdjustment (previsión
            // consecutiva), NO lo sobrescribimos para preservar el
            // "estado verdadero" anterior.
            const species = plant.speciesId
              ? await this.speciesRepo.findById(plant.speciesId).catch(() => null)
              : null;
            const month  = now.getMonth() + 1;
            const factor = getSeasonalFactor(month, species?.seasonalWateringAdjustment);
            const freq   = Math.max(1, Math.round(plant.wateringFrequency * factor));
            const nextWatering = new Date(now);
            nextWatering.setDate(nextWatering.getDate() + freq);

            const updates: Record<string, unknown> = { nextWatering };
            if (!plant.pendingRainAdjustment) {
              updates['pendingRainAdjustment'] = {
                resetAt:              now,
                previousNextWatering: plant.nextWatering ?? null,
                expectedMm:           maxRain,
                locationLat:          plant.plantLocationLat!,
                locationLon:          plant.plantLocationLon!,
              };
            }
            await this.plantRepo.update(plant.id, updates);

            const rainMessage = NotificationMessages.watering.rainPostponed(plant.name, maxRain);
            await this._persistAndPushSocket({
              userId:    plant.userId,
              type:      'watering',
              message:   rainMessage,
              plantId:   plant.id,
              isRead:    false,
              createdAt: now,
            });
            await this.historyRepo.create({
              reminderId:     '',
              processedAt:    now,
              result:         'success',
              idempotencyKey: rainKey,
            });
            summary.created.weather++;
            this._enqueuePush(plant.userId, rainMessage);
            logger.debug(`Alerta de lluvia creada para planta ${plant.id} (${maxRain}%) — nextWatering reseteado + pendingRainAdjustment guardado`);
          }
        }

        // Notificación de tormenta.
        if (stormHour) {
          const stormKey = `weather_storm_${plant.id}_${today}`;
          if (!(await this.historyRepo.exists(stormKey))) {
            const stormMessage = NotificationMessages.watering.stormAlert(plant.name, stormHour.condition);
            await this._persistAndPushSocket({
              userId:    plant.userId,
              type:      'watering',
              message:   stormMessage,
              plantId:   plant.id,
              isRead:    false,
              createdAt: now,
            });
            await this.historyRepo.create({
              reminderId:     '',
              processedAt:    now,
              result:         'success',
              idempotencyKey: stormKey,
            });
            summary.created.weather++;
            this._enqueuePush(plant.userId, stormMessage);
            logger.debug(`Alerta de tormenta creada para planta ${plant.id}`);
          }
        }

      } catch (err) {
        logger.error(`Error procesando clima para planta ${plant.id}: ${(err as Error).message}`);
      }
    }
  }

  /**
   * Comprueba la lluvia caída el día anterior en cada ubicación con plantas
   * de exterior y, si supera el umbral de la especie (minRainfallMm, default 5mm),
   * considera la planta regada: resetea nextWatering a ayer + wateringFrequency
   * (ajustada por estacionalidad) y emite una notificación informativa.
   * Idempotencia diaria: yesterday_rain_{plantId}_{YYYY-MM-DD}.
   * @private
   */
  private async _processYesterdayRain(summary: CronRunSummary): Promise<void> {
    const today      = new Date().toISOString().slice(0, 10);
    const yesterday  = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    const month      = new Date().getMonth() + 1;

    // Plantas de exterior con coordenadas.
    const plants = await this.plantRepo.findPlantsNeedingCare(24 * 30);
    const outdoor = plants.filter(
      (p) => p.location === 'Exterior'
          && p.plantLocationLat != null
          && p.plantLocationLon != null,
    );

    if (outdoor.length === 0) {
      summary.diagnostics.push(`yesterdayRain_no_outdoor (total_plants_in_window=${plants.length})`);
      return;
    }

    // Agrupar por clave de ubicación para evitar múltiples llamadas a WeatherAPI.
    const rainByLocation = new Map<string, number>();

    for (const plant of outdoor) {
      try {
        const locationKey = this.weatherDS.keyForLocation(plant.plantLocationLat!, plant.plantLocationLon!);

        let rainfallMm = rainByLocation.get(locationKey);
        if (rainfallMm === undefined) {
          rainfallMm = await this.weatherDS.fetchYesterdayRainfall(locationKey);
          rainByLocation.set(locationKey, rainfallMm);
        }

        const species = plant.speciesId
          ? await this.speciesRepo.findById(plant.speciesId).catch(() => null)
          : null;
        const threshold = species?.minRainfallMm ?? DEFAULT_MIN_RAINFALL_MM;
        const cityLabel = plant.plantLocation ? ` en ${plant.plantLocation}` : '';
        const speciesLabel = species ? ` (${species.name})` : '';

        // ── Confirmación / rollback de pendingRainAdjustment ──
        // Si la planta tiene un reset pendiente de validación, lo procesamos
        // antes que el flujo "lluvia normal" para evitar duplicar la
        // consulta a history y para tener idempotencia diaria.
        if (plant.pendingRainAdjustment) {
          // Un adjustment creado HOY por _processWeather (mismo execute()
          // del cron) NO debe procesarse aquí. La rain check mira la
          // lluvia de ayer y no tiene relación con la previsión hecha hoy.
          // Procesar el adjustment de hoy con la lluvia de ayer
          // corrompería tanto la rama "confirmar" (atribuye lluvia de ayer
          // a la previsión de hoy) como "rollback" (descarta una previsión
          // que ni siquiera se ha podido verificar). Se difiere a mañana.
          const resetISODate = plant.pendingRainAdjustment.resetAt
            .toISOString().slice(0, 10);
          if (resetISODate >= today) {
            summary.diagnostics.push(`yesterdayRain_skip_sameday (plant=${plant.id})`);
            continue;
          }

          const rollbackKey = `pending_rain_resolve_${plant.id}_${today}`;
          if (await this.historyRepo.exists(rollbackKey)) continue;

          const now = new Date();
          if (rainfallMm >= threshold) {
            // Confirmado: la lluvia cayó. Limpiar el adjustment (null
            // explícito: el schema acepta `['object','null']` y el $set
            // del repo lo persiste tal cual).
            await this.plantRepo.update(
              plant.id,
              { pendingRainAdjustment: null } as unknown as Partial<Plant>,
            );
            const confirmedMsg = NotificationMessages.watering.rainConfirmedAdjustment(
              plant.name, rainfallMm, plant.plantLocation, species?.name,
            );
            await this._persistAndPushSocket({
              userId:    plant.userId,
              type:      'watering',
              message:   confirmedMsg,
              plantId:   plant.id,
              isRead:    false,
              createdAt: now,
            });
            this._enqueuePush(plant.userId, confirmedMsg);
            logger.debug(`pendingRainAdjustment confirmado para planta ${plant.id} (${rainfallMm}mm)`);
          } else {
            // Rollback: la lluvia no llegó. Restaurar previousNextWatering
            // y limpiar el adjustment (mismo patrón de cast que arriba).
            // Si previousNextWatering es null (la planta no tenía
            // nextWatering antes del reset), hacemos fallback a `hoy`
            // (regar hoy) — la previsión falló y no había schedule
            // previo, así que el siguiente riego es ya. Sin este fallback
            // MongoDB $set omitiría el undefined y nextWatering quedaría
            // en el valor de reset, dejando a la planta "marcada como
            // regada" pese al rollback.
            const restored = plant.pendingRainAdjustment.previousNextWatering ?? now;
            await this.plantRepo.update(
              plant.id,
              {
                nextWatering:          restored,
                pendingRainAdjustment: null,
              } as unknown as Partial<Plant>,
            );
            const rollbackMsg = NotificationMessages.watering.rainRollback(
              plant.name, rainfallMm, plant.plantLocation,
            );
            await this._persistAndPushSocket({
              userId:    plant.userId,
              type:      'watering',
              message:   rollbackMsg,
              plantId:   plant.id,
              isRead:    false,
              createdAt: now,
            });
            this._enqueuePush(plant.userId, rollbackMsg);
            logger.debug(`pendingRainAdjustment rollback aplicado a planta ${plant.id} (${rainfallMm}mm < ${threshold}mm)`);
          }
          await this.historyRepo.create({
            reminderId:     '',
            processedAt:    now,
            result:         'success',
            idempotencyKey: rollbackKey,
          });
          summary.created.yesterdayRain++;
          // Importante: NO seguir al flujo "lluvia normal" — el adjustment
          // ya cubrió el evento del día (evita doble notificación).
          continue;
        }

        if (rainfallMm < threshold) continue;

        const rainKey = `yesterday_rain_${plant.id}_${today}`;
        if (await this.historyRepo.exists(rainKey)) continue;

        // Nueva fecha de riego: ayer + frecuencia ajustada por estacionalidad.
        const factor = getSeasonalFactor(month, species?.seasonalWateringAdjustment);
        const freq   = Math.max(1, Math.round(plant.wateringFrequency * factor));
        const nextWatering = new Date(yesterday);
        nextWatering.setDate(nextWatering.getDate() + freq);

        // La lluvia solo debe POSPONER el riego. Si la planta YA tiene un
        // nextWatering posterior (p. ej. el usuario la regó hoy con
        // freq=10 y la lluvia de ayer solo da +9), aplicar este reset
        // tiraría nextWatering hacia atrás — la planta aparecería más
        // urgente tras la lluvia, lo cual es contraintuitivo. Solo
        // actualizamos si el nuevo nextWatering es ESTRICTAMENTE posterior.
        if (plant.nextWatering && nextWatering <= plant.nextWatering) {
          summary.diagnostics.push(
            `yesterdayRain_skip_no_improvement (plant=${plant.id}, current=${plant.nextWatering.toISOString().slice(0,10)}, new=${nextWatering.toISOString().slice(0,10)})`,
          );
          continue;
        }

        await this.plantRepo.update(plant.id, { nextWatering });

        const now = new Date();

        const rainConfirmedMsg = NotificationMessages.watering.rainConfirmed(
          plant.name, rainfallMm, plant.plantLocation, species?.name,
        );
        await this._persistAndPushSocket({
          userId:    plant.userId,
          type:      'watering',
          message:   rainConfirmedMsg,
          plantId:   plant.id,
          isRead:    false,
          createdAt: now,
        });

        await this.historyRepo.create({
          reminderId:     '',
          processedAt:    now,
          result:         'success',
          idempotencyKey: rainKey,
        });

        summary.created.yesterdayRain++;
        this._enqueuePush(plant.userId, rainConfirmedMsg);
        logger.debug(`Lluvia de ayer aplicada a planta ${plant.id} (${rainfallMm}mm >= ${threshold}mm)`);

      } catch (err) {
        logger.error(`Error procesando lluvia de ayer para planta ${plant.id}: ${(err as Error).message}`);
      }
    }
  }

  /**
   * Genera notificaciones de poda para las plantas cuya especie tiene poda
   * programada en el mes actual. Ejecuta los días 1 y 15 del mes.
   * Idempotencia: prune_{plantId}_{year}_{month}_d1 / prune_{plantId}_{year}_{month}_d15.
   * @private
   */
  private async _processPruning(summary: CronRunSummary): Promise<void> {
    const now          = new Date();
    const currentMonth = now.getMonth() + 1;
    const dayOfMonth   = now.getDate();

    // Solo generar notificaciones de poda los días 1 y 15 del mes.
    if (dayOfMonth !== 1 && dayOfMonth !== 15) {
      summary.diagnostics.push(`pruning_day_gated (today=${dayOfMonth}, runs_on=1/15)`);
      return;
    }

    const daySuffix = dayOfMonth === 1 ? 'd1' : 'd15';

    const pruningSpecies = await this.speciesRepo.findPruningThisMonth(currentMonth);
    if (pruningSpecies.length === 0) {
      summary.diagnostics.push(`pruning_no_species_this_month (month=${currentMonth})`);
      return;
    }

    logger.info(`ProcessPruning: ${pruningSpecies.length} especie(s) con poda en mes ${currentMonth} (${daySuffix})`);

    let totalPlants   = 0;
    let skippedIdem   = 0;
    for (const species of pruningSpecies) {
      const plants = await this.plantRepo.findBySpeciesId(species.id);
      totalPlants += plants.length;

      for (const plant of plants) {
        const pruneKey = `prune_${plant.id}_${now.getFullYear()}_${currentMonth}_${daySuffix}`;

        try {
          const alreadyProcessed = await this.historyRepo.exists(pruneKey);
          if (alreadyProcessed) { skippedIdem++; continue; }

          const message = NotificationMessages.pruning.pending(plant.name, species.name);

          await this._persistAndPushSocket({
            userId:    plant.userId,
            type:      'pruning',
            message,
            plantId:   plant.id,
            isRead:    false,
            createdAt: now,
          });

          await this.historyRepo.create({
            reminderId:     '',
            processedAt:    now,
            result:         'success',
            idempotencyKey: pruneKey,
          });

          summary.created.pruning++;
          this._enqueuePush(plant.userId, message);
          logger.debug(`Notificación de poda creada para planta ${plant.id}`);

        } catch (err) {
          logger.error(`Error generando poda para planta ${plant.id}: ${(err as Error).message}`);
        }
      }
    }

    if (totalPlants === 0) summary.diagnostics.push('pruning_no_plants_with_species (stale speciesId?)');
    if (skippedIdem > 0)   summary.diagnostics.push(`pruning_idem=${skippedIdem}`);
  }

  /**
   * Genera notificaciones de cosecha para las plantas cuya especie produce fruto
   * en el mes actual. Ejecuta los días 1 y 15 del mes.
   * Idempotencia: harvest_{plantId}_{year}_{month}_d1 / harvest_{plantId}_{year}_{month}_d15.
   * @private
   */
  private async _processHarvest(summary: CronRunSummary): Promise<void> {
    const now          = new Date();
    const currentMonth = now.getMonth() + 1;
    const dayOfMonth   = now.getDate();

    // Solo generar notificaciones de cosecha los días 1 y 15 del mes.
    if (dayOfMonth !== 1 && dayOfMonth !== 15) {
      summary.diagnostics.push(`harvest_day_gated (today=${dayOfMonth}, runs_on=1/15)`);
      return;
    }

    const daySuffix = dayOfMonth === 1 ? 'd1' : 'd15';

    const fruitingSpecies = await this.speciesRepo.findFruitingThisMonth(currentMonth);
    if (fruitingSpecies.length === 0) {
      summary.diagnostics.push(`harvest_no_species_this_month (month=${currentMonth})`);
      return;
    }

    logger.info(`ProcessHarvest: ${fruitingSpecies.length} especie(s) con cosecha en mes ${currentMonth} (${daySuffix})`);

    let totalPlants = 0;
    let skippedIdem = 0;
    for (const species of fruitingSpecies) {
      const plants = await this.plantRepo.findBySpeciesId(species.id);
      totalPlants += plants.length;

      for (const plant of plants) {
        const harvestKey = `harvest_${plant.id}_${now.getFullYear()}_${currentMonth}_${daySuffix}`;

        try {
          const alreadyProcessed = await this.historyRepo.exists(harvestKey);
          if (alreadyProcessed) { skippedIdem++; continue; }

          const message = NotificationMessages.harvest.pending(plant.name, species.name);

          await this._persistAndPushSocket({
            userId:    plant.userId,
            type:      'harvest',
            message,
            plantId:   plant.id,
            isRead:    false,
            createdAt: now,
          });

          await this.historyRepo.create({
            reminderId:     '',
            processedAt:    now,
            result:         'success',
            idempotencyKey: harvestKey,
          });

          summary.created.harvest++;
          this._enqueuePush(plant.userId, message);
          logger.debug(`Notificación de cosecha creada para planta ${plant.id}`);

        } catch (err) {
          logger.error(`Error generando cosecha para planta ${plant.id}: ${(err as Error).message}`);
        }
      }
    }

    if (totalPlants === 0) summary.diagnostics.push('harvest_no_plants_with_species (stale speciesId?)');
    if (skippedIdem > 0)   summary.diagnostics.push(`harvest_idem=${skippedIdem}`);
  }
}
