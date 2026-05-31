/**
 * @file WeatherService.ts
 * @description Servicio de meteorología.
 * Orquesta WeatherAPIDataSource + IWeatherCacheRepository:
 *   1. Consulta caché por locationKey.
 *   2. Si ausente o expirada, llama a WeatherAPIDataSource.
 *   3. Persiste los datos nuevos en caché.
 * Expone shouldWater() para determinar si se debe regar según el pronóstico.
 * TFG: el fallback a caché expirada en caso de 429 se implementará en producción;
 *      en esta fase se relanza la excepción para que el controller devuelva 503.
 * @module Weather
 * @layer Presentation
 *
 * @injectable
 * @dependencies WeatherAPIDataSource, IWeatherCacheRepository, IWeatherMapper
 */

import { injectable, inject } from 'inversify';
import { TYPES } from '../../core/types.js';
import { weatherConfig } from '../../core/config/weather.config.js';
import { WeatherAPIDataSource } from '../../data/datasources/external/WeatherAPIDataSource.js';
import type { IWeatherCacheRepository } from '../../domain/repositories/IWeatherCacheRepository.js';
import type { IWeatherMapper } from '../../data/IMappers/IWeatherMapper.js';
import type { WeatherResponseDTO } from '../../domain/dtos/weather/weather-response.dto.js';
import type { ForecastResponseDTO } from '../../domain/dtos/weather/forecast-response.dto.js';
import { createLogger } from '../../core/logger.js';

const logger = createLogger('WeatherService');

/**
 * Servicio de meteorología — orquestación de caché y datasource.
 *
 * @injectable
 * @dependencies WeatherAPIDataSource, IWeatherCacheRepository, IWeatherMapper
 */
@injectable()
export class WeatherService {
  constructor(
    @inject(TYPES.WeatherDataSource)       private readonly dataSource: WeatherAPIDataSource,
    @inject(TYPES.IWeatherCacheRepository) private readonly cacheRepo: IWeatherCacheRepository,
    @inject(TYPES.IWeatherCacheMapper)     private readonly mapper: IWeatherMapper,
  ) {}

  /**
   * Devuelve el clima actual para una localización en formato string.
   * Acepta cualquier valor que WeatherAPI.com pueda resolver: nombre de ciudad,
   * coordenadas ("lat,lon"), código postal, etc.
   * Usa caché si es válida; refresca si ha expirado.
   *
   * @param location — String de localización libre (ej. "Sevilla", "37.39,-5.99").
   * @returns WeatherResponseDTO.
   * @throws {ExternalServiceException} Si la API falla y no hay caché disponible.
   */
  async getWeatherForQuery(location: string): Promise<WeatherResponseDTO> {
    // Normalizar: trim y lowercase como clave de caché consistente.
    const locationKey = location.trim();

    const cached = await this.cacheRepo.findByLocationKey(locationKey);
    if (cached) {
      logger.debug(`WeatherService: cache hit para "${locationKey}"`);
      return this.mapper.toWeatherResponseDTO(cached);
    }

    const data = await this.dataSource.fetchWeatherData(locationKey, weatherConfig.WEATHER_WINDOW_HOURS);
    const now  = new Date();
    const expiresAt = new Date(now.getTime() + weatherConfig.WEATHER_CACHE_TTL_SECONDS * 1000);

    const saved = await this.cacheRepo.save({ locationKey, data, fetchedAt: now, expiresAt });
    logger.debug(`WeatherService: datos frescos guardados para "${locationKey}"`);
    return this.mapper.toWeatherResponseDTO(saved);
  }

  /**
   * Devuelve el clima actual para unas coordenadas geográficas.
   * Usa caché si es válida; refresca si ha expirado.
   *
   * @param lat — Latitud.
   * @param lon — Longitud.
   * @returns WeatherResponseDTO.
   * @throws {ExternalServiceException} Si la API falla y no hay caché disponible.
   */
  async getWeatherForLocation(lat: number, lon: number): Promise<WeatherResponseDTO> {
    const locationKey = this.dataSource.keyForLocation(lat, lon);

    // 1. Comprobar caché vigente
    const cached = await this.cacheRepo.findByLocationKey(locationKey);
    if (cached) {
      logger.debug(`WeatherService: cache hit para ${locationKey}`);
      return this.mapper.toWeatherResponseDTO(cached);
    }

    // 2. Refrescar desde la API
    const data = await this.dataSource.fetchWeatherData(locationKey, weatherConfig.WEATHER_WINDOW_HOURS);
    const now  = new Date();
    const expiresAt = new Date(now.getTime() + weatherConfig.WEATHER_CACHE_TTL_SECONDS * 1000);

    const saved = await this.cacheRepo.save({
      locationKey,
      data,
      fetchedAt: now,
      expiresAt,
    });

    logger.debug(`WeatherService: datos frescos guardados para ${locationKey}`);
    return this.mapper.toWeatherResponseDTO(saved);
  }

  /**
   * Devuelve la previsión horaria para una localización en formato string.
   *
   * @param location — String de localización libre.
   * @param hours — Número de horas de previsión (1–48).
   * @returns ForecastResponseDTO.
   * @throws {ExternalServiceException} Si la API falla y no hay caché disponible.
   */
  async getForecastForQuery(location: string, hours = 24): Promise<ForecastResponseDTO> {
    const locationKey = location.trim();

    const cached = await this.cacheRepo.findByLocationKey(locationKey);
    if (cached) {
      logger.debug(`WeatherService: forecast cache hit para "${locationKey}"`);
      return this.mapper.toForecastResponseDTO(cached, hours);
    }

    const data = await this.dataSource.fetchWeatherData(locationKey, hours);
    const now  = new Date();
    const expiresAt = new Date(now.getTime() + weatherConfig.WEATHER_CACHE_TTL_SECONDS * 1000);

    const saved = await this.cacheRepo.save({ locationKey, data, fetchedAt: now, expiresAt });
    logger.debug(`WeatherService: previsión guardada para "${locationKey}" (${hours}h)`);
    return this.mapper.toForecastResponseDTO(saved, hours);
  }

  /**
   * Devuelve la previsión horaria para unas coordenadas geográficas.
   *
   * @param lat — Latitud.
   * @param lon — Longitud.
   * @param hours — Número de horas de previsión (1–48).
   * @returns ForecastResponseDTO.
   * @throws {ExternalServiceException} Si la API falla y no hay caché disponible.
   */
  async getForecast(lat: number, lon: number, hours = 24): Promise<ForecastResponseDTO> {
    const locationKey = this.dataSource.keyForLocation(lat, lon);

    const cached = await this.cacheRepo.findByLocationKey(locationKey);
    if (cached) {
      logger.debug(`WeatherService: forecast cache hit para ${locationKey}`);
      return this.mapper.toForecastResponseDTO(cached, hours);
    }

    const data = await this.dataSource.fetchWeatherData(locationKey, hours);
    const now  = new Date();
    const expiresAt = new Date(now.getTime() + weatherConfig.WEATHER_CACHE_TTL_SECONDS * 1000);

    const saved = await this.cacheRepo.save({
      locationKey,
      data,
      fetchedAt: now,
      expiresAt,
    });

    logger.debug(`WeatherService: previsión guardada para ${locationKey} (${hours}h)`);
    return this.mapper.toForecastResponseDTO(saved, hours);
  }

  /**
   * Determina si se debe regar en función del pronóstico de lluvia.
   * Devuelve true si se debe regar (no se espera lluvia suficiente).
   * Devuelve true también si no hay datos disponibles (por precaución).
   *
   * @param lat — Latitud de la planta.
   * @param lon — Longitud de la planta.
   * @returns true si se recomienda regar; false si se espera lluvia.
   */
  async shouldWater(lat: number, lon: number): Promise<boolean> {
    const RAIN_THRESHOLD = 60; // % de probabilidad de lluvia para omitir riego
    try {
      const forecast = await this.getForecast(lat, lon, weatherConfig.WEATHER_WINDOW_HOURS);
      const willRain = forecast.hours.some((h) => h.rainProbability >= RAIN_THRESHOLD);
      return !willRain;
    } catch {
      // Sin datos meteorológicos → regar por precaución
      return true;
    }
  }
}
