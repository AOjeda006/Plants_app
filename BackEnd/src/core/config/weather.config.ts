/**
 * @file weather.config.ts
 * @description Configuración del servicio de meteorología (WeatherAPI.com) y su caché.
 * @module Weather
 * @layer Core
 */

import 'dotenv/config';

/**
 * Configuración de WeatherAPI cargada desde variables de entorno.
 */
export const weatherConfig = {
  /** API key de WeatherAPI.com */
  WEATHER_API_KEY: process.env.WEATHER_API_KEY ?? '',

  /** URL base de la API de meteorología */
  WEATHER_API_URL: 'https://api.weatherapi.com/v1',

  /** Horas hacia adelante que se consideran para alertas de riego */
  WEATHER_WINDOW_HOURS: parseInt(process.env.WEATHER_WINDOW_HOURS ?? '48', 10),

  /** TTL en segundos para la caché de respuestas meteorológicas */
  WEATHER_CACHE_TTL_SECONDS: parseInt(process.env.WEATHER_CACHE_TTL_SECONDS ?? '300', 10),

  /**
   * Si true, devuelve datos simulados sin llamar a la API real.
   * TFG: activar en desarrollo para evitar consumir cuota del tier gratuito.
   */
  MOCK_WEATHER_MODE: process.env.MOCK_WEATHER_MODE === 'true',
} as const;
