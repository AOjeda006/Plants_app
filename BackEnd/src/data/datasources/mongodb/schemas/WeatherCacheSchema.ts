/**
 * @file WeatherCacheSchema.ts
 * @description Validador JSON de la colección weather_cache en MongoDB.
 * Garantiza consistencia de tipos en escritura.
 * @module Weather
 * @layer Data
 */

/**
 * JSON Schema validator para la colección weather_cache.
 * El campo data es flexible (object) para acomodar estructuras de WeatherAPI.com.
 */
export const WEATHER_CACHE_SCHEMA = {
  bsonType: 'object',
  required: ['locationKey', 'data', 'fetchedAt', 'expiresAt'],
  properties: {
    locationKey: { bsonType: 'string',   description: 'Clave normalizada lat,lon' },
    data:        { bsonType: 'object',   description: 'Condiciones actuales + previsión' },
    fetchedAt:   { bsonType: 'date',     description: 'Momento de obtención de los datos' },
    expiresAt:   { bsonType: 'date',     description: 'Momento de expiración de la caché' },
  },
} as const;
