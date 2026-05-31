/**
 * @file WeatherCacheModel.ts
 * @description Define el nombre de la colección y el tipo del documento MongoDB para WeatherCache.
 * SIN lógica de mapeo — la transformación entre documento y entidad es responsabilidad
 * exclusiva del mapper (data/mappers/weather_mapper.ts).
 * @module Weather
 * @layer Data
 */

import { ObjectId } from 'mongodb';
import type { WeatherCacheData } from '../../../../domain/entities/WeatherCache.js';

/** Nombre de la colección en MongoDB */
export const WEATHER_CACHE_COLLECTION = 'weather_cache';

/**
 * Tipo del documento MongoDB tal como se almacena en la base de datos.
 * El campo data almacena WeatherCacheData en formato serializable.
 */
export interface WeatherCacheDocument {
  _id:         ObjectId;
  locationKey: string;
  data:        WeatherCacheData;
  fetchedAt:   Date;
  expiresAt:   Date;
}
