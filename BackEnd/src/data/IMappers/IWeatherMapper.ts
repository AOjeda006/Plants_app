/**
 * @file IWeatherMapper.ts
 * @description Interfaz del mapper de datos meteorológicos.
 * Convierte entre WeatherCacheDocument (MongoDB), WeatherCache (entidad) y los DTOs de respuesta.
 * @module Weather
 * @layer Data
 */

import type { WeatherCache } from '../../domain/entities/WeatherCache.js';
import type { WeatherCacheDocument } from '../datasources/mongodb/models/WeatherCacheModel.js';
import type { WeatherResponseDTO } from '../../domain/dtos/weather/weather-response.dto.js';
import type { ForecastResponseDTO } from '../../domain/dtos/weather/forecast-response.dto.js';

/**
 * Mapper de WeatherCache: document ↔ entity ↔ DTOs de respuesta.
 */
export interface IWeatherMapper {
  /**
   * Convierte un documento MongoDB en entidad de dominio WeatherCache.
   *
   * @param doc — Documento de la colección weather_cache.
   * @returns WeatherCache
   */
  toEntity(doc: WeatherCacheDocument): WeatherCache;

  /**
   * Convierte una entidad WeatherCache en documento MongoDB.
   * NO incluye _id (se asigna en el repositorio).
   *
   * @param entity — Entidad de dominio.
   * @returns Omit<WeatherCacheDocument, '_id'>
   */
  toDocument(entity: WeatherCache): Omit<WeatherCacheDocument, '_id'>;

  /**
   * Convierte la entidad WeatherCache en DTO de clima actual.
   *
   * @param entity — Entidad de dominio.
   * @returns WeatherResponseDTO
   */
  toWeatherResponseDTO(entity: WeatherCache): WeatherResponseDTO;

  /**
   * Convierte la entidad WeatherCache en DTO de previsión por horas.
   *
   * @param entity — Entidad de dominio.
   * @param hours — Número máximo de horas a incluir.
   * @returns ForecastResponseDTO
   */
  toForecastResponseDTO(entity: WeatherCache, hours?: number): ForecastResponseDTO;
}
