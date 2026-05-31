/**
 * @file weather_mapper.ts
 * @description Implementación del mapper de datos meteorológicos.
 * Convierte entre WeatherCacheDocument (MongoDB), WeatherCache (entidad) y DTOs de respuesta.
 * @module Weather
 * @layer Data
 *
 * @implements {IWeatherMapper}
 * @injectable
 */

import { injectable } from 'inversify';
import type { IWeatherMapper } from '../IMappers/IWeatherMapper.js';
import { WeatherCache } from '../../domain/entities/WeatherCache.js';
import type { WeatherCacheDocument } from '../datasources/mongodb/models/WeatherCacheModel.js';
import type { WeatherResponseDTO } from '../../domain/dtos/weather/weather-response.dto.js';
import type { ForecastResponseDTO, WeatherHourDTO } from '../../domain/dtos/weather/forecast-response.dto.js';

/**
 * Mapper de WeatherCache.
 *
 * @implements {IWeatherMapper}
 * @injectable
 */
@injectable()
export class WeatherMapper implements IWeatherMapper {
  /**
   * Convierte un documento MongoDB en entidad WeatherCache.
   *
   * @param doc — Documento de la colección weather_cache.
   * @returns WeatherCache
   */
  toEntity(doc: WeatherCacheDocument): WeatherCache {
    return new WeatherCache({
      id:          doc._id.toHexString(),
      locationKey: doc.locationKey,
      data:        doc.data,
      fetchedAt:   doc.fetchedAt,
      expiresAt:   doc.expiresAt,
    });
  }

  /**
   * Convierte una entidad WeatherCache en documento MongoDB sin _id.
   *
   * @param entity — Entidad de dominio.
   * @returns Omit<WeatherCacheDocument, '_id'>
   */
  toDocument(entity: WeatherCache): Omit<WeatherCacheDocument, '_id'> {
    return {
      locationKey: entity.locationKey,
      data:        entity.data,
      fetchedAt:   entity.fetchedAt,
      expiresAt:   entity.expiresAt,
    };
  }

  /**
   * Convierte la entidad WeatherCache en DTO de clima actual.
   *
   * @param entity — Entidad de dominio.
   * @returns WeatherResponseDTO
   */
  toWeatherResponseDTO(entity: WeatherCache): WeatherResponseDTO {
    const { current } = entity.data;
    return {
      locationKey:     entity.locationKey,
      temperature:     current.temperature,
      feelsLike:       current.feelsLike,
      humidity:        current.humidity,
      windSpeed:       current.windSpeed,
      condition:       current.condition,
      icon:            current.icon,
      rainProbability: current.rainProbability,
      fetchedAt:       entity.fetchedAt.toISOString(),
    };
  }

  /**
   * Convierte la entidad WeatherCache en DTO de previsión por horas.
   *
   * @param entity — Entidad de dominio.
   * @param hours — Número máximo de horas a incluir (por defecto todas).
   * @returns ForecastResponseDTO
   */
  toForecastResponseDTO(entity: WeatherCache, hours?: number): ForecastResponseDTO {
    const forecastSlice = hours
      ? entity.data.forecast.slice(0, hours)
      : entity.data.forecast;

    const hourDTOs: WeatherHourDTO[] = forecastSlice.map((h) => ({
      hour:            h.hour,
      temperature:     h.temperature,
      humidity:        h.humidity,
      rainProbability: h.rainProbability,
      condition:       h.condition,
      willItRain:      h.willItRain,
    }));

    return {
      locationKey: entity.locationKey,
      hours:       hourDTOs,
      fetchedAt:   entity.fetchedAt.toISOString(),
    };
  }
}
