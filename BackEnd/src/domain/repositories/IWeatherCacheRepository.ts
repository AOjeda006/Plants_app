/**
 * @file IWeatherCacheRepository.ts
 * @description Interfaz del repositorio de caché meteorológica.
 * @module Weather
 * @layer Domain
 */

import type { WeatherCache } from '../entities/WeatherCache.js';
import type { ClientSession } from 'mongodb';

export interface IWeatherCacheRepository {
  /**
   * Busca la entrada de caché para una clave de localización.
   * Devuelve null si no existe o si ha expirado.
   *
   * @param locationKey — Clave normalizada (ej.: "40.4168,-3.7038").
   * @returns WeatherCache o null.
   */
  findByLocationKey(locationKey: string): Promise<WeatherCache | null>;

  /**
   * Crea o reemplaza la entrada de caché para una localización.
   * Usa upsert para garantizar unicidad por locationKey.
   *
   * @param cache — Datos de la caché sin id.
   * @param session — Sesión de transacción opcional.
   * @returns WeatherCache persistida.
   */
  save(cache: Omit<WeatherCache, 'id' | 'isExpired'>, session?: ClientSession): Promise<WeatherCache>;

  /**
   * Elimina todas las entradas de caché cuyo expiresAt sea anterior a now.
   * Invocado por CleanupExpiredWeatherCacheJob.
   *
   * @returns Número de documentos eliminados.
   */
  deleteExpired(): Promise<number>;
}
