/**
 * @file IPlantRepository.ts
 * @description Interfaz del repositorio de plantas. Define el contrato de acceso a datos
 * sin acoplar la capa de dominio a ninguna implementación concreta.
 * @module Plants
 * @layer Domain
 */

import type { ClientSession } from 'mongodb';
import type { Plant } from '../entities/Plant.js';

/**
 * Contrato del repositorio de plantas.
 * Los use cases dependen de esta interfaz, nunca de la implementación concreta.
 */
export interface IPlantRepository {
  /**
   * Obtiene todas las plantas activas de un usuario.
   *
   * @param userId — Id del usuario propietario.
   * @returns Lista de plantas (sin deletedAt).
   */
  findByUserId(userId: string): Promise<Plant[]>;

  /**
   * Busca una planta por su id (incluye borradas lógicamente).
   *
   * @param id — Id de la planta.
   * @returns Planta encontrada o null.
   */
  findById(id: string): Promise<Plant | null>;

  /**
   * Crea una nueva planta en la base de datos.
   *
   * @param plant — Datos de la planta sin id.
   * @param session — Sesión de transacción opcional.
   * @returns Planta creada con id asignado.
   */
  create(plant: Omit<Plant, 'id'>, session?: ClientSession): Promise<Plant>;

  /**
   * Actualiza los campos indicados de una planta existente.
   *
   * @param id — Id de la planta.
   * @param data — Campos parciales a actualizar.
   * @param session — Sesión de transacción opcional.
   * @returns Planta actualizada.
   * @throws {NotFoundException} Si la planta no existe.
   */
  update(
    id: string,
    data: Partial<Omit<Plant, 'id' | 'createdAt'>>,
    session?: ClientSession,
  ): Promise<Plant>;

  /**
   * Elimina una planta (soft delete por defecto).
   *
   * @param id — Id de la planta.
   * @param soft — true → marcar deletedAt. false → eliminar físicamente.
   * @param session — Sesión de transacción opcional.
   * @throws {NotFoundException} Si la planta no existe.
   */
  delete(id: string, soft?: boolean, session?: ClientSession): Promise<void>;

  /**
   * Busca todas las plantas activas que tienen asignada una especie concreta.
   * Usado por el cron job de cosecha para encontrar plantas frutales.
   *
   * @param speciesId — Id de la especie.
   * @returns Lista de plantas no eliminadas con esa especie.
   */
  findBySpeciesId(speciesId: string): Promise<Plant[]>;

  /**
   * Busca plantas que necesitan atención dentro de una ventana temporal.
   * Usado por el ReminderCronJob para procesar recordatorios pendientes.
   *
   * @param windowHours — Horas hacia el futuro a considerar (por defecto 24h).
   * @returns Lista de plantas cuyo nextWatering está dentro de la ventana.
   */
  findPlantsNeedingCare(windowHours?: number): Promise<Plant[]>;

  /**
   * Devuelve los userIds únicos de usuarios que tienen al menos una planta activa.
   * Usado por el cron job para generar la notificación "Todo al día".
   *
   * @returns Lista de userIds distintos.
   */
  findDistinctUserIds(): Promise<string[]>;
}
