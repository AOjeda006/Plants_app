/**
 * @file ReminderService.ts
 * @description Servicio de recordatorios de riego/poda.
 * Orquesta la creación, cancelación y ajuste climático de recordatorios.
 * - scheduleReminder: crea un nuevo recordatorio para una planta.
 * - cancelReminder: suspende un recordatorio activo.
 * - adjustByWeather: pospone recordatorios de riego si se prevé lluvia.
 * @module Reminders
 * @layer Presentation
 *
 * @injectable
 * @dependencies IReminderRepository, WeatherService
 */

import { injectable, inject } from 'inversify';
import { TYPES } from '../../core/types.js';
import type { IReminderRepository } from '../../domain/repositories/IReminderRepository.js';
import { Reminder, ReminderType } from '../../domain/entities/Reminder.js';
import { WeatherService } from './WeatherService.js';
import { NotFoundException } from '../../core/exceptions/NotFoundException.js';
import { createLogger } from '../../core/logger.js';

const logger = createLogger('ReminderService');

/** Parámetros para crear un recordatorio */
export interface ScheduleReminderParams {
  plantId:       string;
  userId:        string;
  type:          ReminderType;
  scheduledDate: Date;
  message:       string;
}

/**
 * Servicio de recordatorios — orquestación de dominio y consulta climática.
 *
 * @injectable
 * @dependencies IReminderRepository, WeatherService
 */
@injectable()
export class ReminderService {
  constructor(
    @inject(TYPES.IReminderRepository) private readonly reminderRepo: IReminderRepository,
    @inject(TYPES.WeatherService)      private readonly weatherService: WeatherService,
  ) {}

  /**
   * Crea y persiste un nuevo recordatorio.
   *
   * @param params — Datos del recordatorio a programar.
   * @returns Reminder creado.
   */
  async scheduleReminder(params: ScheduleReminderParams): Promise<Reminder> {
    const reminder = await this.reminderRepo.create({
      plantId:       params.plantId,
      userId:        params.userId,
      type:          params.type,
      scheduledDate: params.scheduledDate,
      message:       params.message,
      isCompleted:   false,
      suspended:     false,
      attempts:      0,
      createdAt:     new Date(),
    } as Omit<Reminder, 'id' | 'isPending'>);

    logger.info(`Recordatorio programado: ${reminder.id} tipo=${reminder.type} fecha=${reminder.scheduledDate.toISOString()}`);
    return reminder;
  }

  /**
   * Suspende (cancela) un recordatorio activo.
   * Lanza NotFoundException si no existe.
   *
   * @param reminderId — Id del recordatorio.
   * @param userId — Id del usuario propietario (para validar acceso).
   * @throws {NotFoundException} Si el recordatorio no existe.
   */
  async cancelReminder(reminderId: string, userId: string): Promise<void> {
    const reminders = await this.reminderRepo.findByUserId(userId);
    const exists = reminders.some((r) => r.id === reminderId);
    if (!exists) throw new NotFoundException('Reminder', reminderId);

    await this.reminderRepo.updateStatus(reminderId, { suspended: true });
    logger.info(`Recordatorio cancelado: ${reminderId}`);
  }

  /**
   * Ajusta recordatorios de riego de un usuario según el pronóstico meteorológico.
   * Si no se debe regar (se espera lluvia), pospone 24 h los recordatorios pendientes de hoy.
   * TFG: solo aplica a recordatorios de tipo 'watering' con scheduledDate <= 24 h.
   *
   * @param userId — Id del usuario.
   * @param lat — Latitud de referencia (localización del usuario o planta).
   * @param lon — Longitud de referencia.
   * @returns Número de recordatorios ajustados.
   */
  async adjustByWeather(userId: string, lat: number, lon: number): Promise<number> {
    const shouldWater = await this.weatherService.shouldWater(lat, lon);
    if (shouldWater) {
      logger.debug(`adjustByWeather: sin lluvia prevista para (${lat},${lon}) — sin cambios`);
      return 0;
    }

    const reminders = await this.reminderRepo.findByUserId(userId);
    const now   = new Date();
    const in24h = new Date(now.getTime() + 24 * 60 * 60 * 1000);

    // Solo recordatorios de riego con fecha <= 24 h
    const toPostpone = reminders.filter(
      (r) => r.type === 'watering' && r.scheduledDate <= in24h && !r.isCompleted,
    );

    for (const reminder of toPostpone) {
      const newDate = new Date(reminder.scheduledDate.getTime() + 24 * 60 * 60 * 1000);
      await this.reminderRepo.updateStatus(reminder.id, { scheduledDate: newDate });
      logger.info(`Recordatorio ${reminder.id} pospuesto 24h por previsión de lluvia`);
    }

    return toPostpone.length;
  }
}
