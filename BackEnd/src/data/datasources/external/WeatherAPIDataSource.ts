/**
 * @file WeatherAPIDataSource.ts
 * @description Datasource para la API de WeatherAPI.com.
 * Obtiene condiciones actuales y previsión horaria.
 * Soporta MOCK_WEATHER_MODE para desarrollo/TFG sin consumir cuota.
 * Lanza ExternalServiceException si la API devuelve error o no responde.
 * @module Weather
 * @layer Data
 *
 * @injectable
 * @dependencies weatherConfig
 */

import { injectable } from 'inversify';
import axios, { AxiosError } from 'axios';
import { weatherConfig } from '../../../core/config/weather.config.js';
import { ExternalServiceException } from '../../../core/exceptions/ExternalServiceException.js';
import { createLogger } from '../../../core/logger.js';
import type { WeatherCacheData, WeatherConditionData, WeatherHourData } from '../../../domain/entities/WeatherCache.js';

const logger = createLogger('WeatherAPIDataSource');

// ─── Tipos internos de la API de WeatherAPI.com ───────────────────────────

interface ApiCurrentResponse {
  current: {
    temp_c:       number;
    feelslike_c:  number;
    humidity:     number;
    wind_kph:     number;
    precip_mm:    number;
    condition:    { text: string; icon: string };
  };
}

interface ApiHour {
  time:          string;
  temp_c:        number;
  humidity:      number;
  chance_of_rain: number;
  will_it_rain:  number; // 0 o 1
  condition:     { text: string };
}

interface ApiForecastResponse {
  current: ApiCurrentResponse['current'];
  forecast: {
    forecastday: Array<{ hour: ApiHour[] }>;
  };
}

/**
 * Respuesta reducida del endpoint history.json de WeatherAPI.com.
 * Solo interesan los totales diarios de precipitación.
 */
interface ApiHistoryResponse {
  forecast: {
    forecastday: Array<{ day: { totalprecip_mm: number } }>;
  };
}

// ─── Datos simulados para MOCK_WEATHER_MODE ───────────────────────────────

// Mock data en español (coherente con `lang=es` que aplica a las llamadas
// reales). Sin la traducción, "Partly cloudy" o "Light rain" aparecerían
// en notificaciones del cron cuando MOCK_WEATHER_MODE está activo.
const MOCK_DATA: WeatherCacheData = {
  current: {
    temperature:     22,
    feelsLike:       21,
    humidity:        55,
    windSpeed:       10,
    condition:       'Parcialmente nublado',
    icon:            '//cdn.weatherapi.com/weather/64x64/day/116.png',
    rainProbability: 10,
  },
  forecast: Array.from({ length: 48 }, (_, i) => ({
    hour:            new Date(Date.now() + i * 3_600_000).toISOString(),
    temperature:     20 + Math.round(Math.sin(i / 6) * 4),
    humidity:        55 + Math.round(Math.cos(i / 4) * 10),
    rainProbability: i % 12 === 0 ? 30 : 5,
    condition:       i % 12 === 0 ? 'Lluvia ligera' : 'Parcialmente nublado',
    willItRain:      i % 12 === 0,
  } satisfies WeatherHourData)),
};

/**
 * Datasource de meteorología (WeatherAPI.com).
 *
 * @injectable
 */
@injectable()
export class WeatherAPIDataSource {
  /**
   * Normaliza lat/lon a una clave de localización reproducible.
   * Ejemplo: keyForLocation(40.41678, -3.70379) → "40.4168,-3.7038"
   *
   * @param lat — Latitud.
   * @param lon — Longitud.
   * @returns Clave de localización.
   */
  keyForLocation(lat: number, lon: number): string {
    return `${lat.toFixed(4)},${lon.toFixed(4)}`;
  }

  /**
   * Obtiene condiciones actuales + previsión de hasta 48 h para una localización.
   * Si MOCK_WEATHER_MODE=true, devuelve datos simulados sin llamar a la API.
   *
   * @param locationKey — Clave normalizada lat,lon.
   * @param hours — Horas de previsión (1–48; por defecto 24).
   * @returns WeatherCacheData con current + forecast.
   * @throws {ExternalServiceException} Si la API devuelve error no recuperable.
   */
  async fetchWeatherData(locationKey: string, hours = 24): Promise<WeatherCacheData> {
    if (weatherConfig.MOCK_WEATHER_MODE) {
      logger.debug(`MOCK_WEATHER_MODE activo — devolviendo datos simulados para ${locationKey}`);
      return {
        ...MOCK_DATA,
        forecast: MOCK_DATA.forecast.slice(0, hours),
      };
    }

    try {
      // Usar endpoint forecast para obtener tanto current como hourly en una sola llamada
      const days = Math.ceil(hours / 24);
      const url  = `${weatherConfig.WEATHER_API_URL}/forecast.json`;

      const response = await axios.get<ApiForecastResponse>(url, {
        // lang=es para que condition.text llegue ya traducido. Cualquier
        // cadena recibida del cliente se reusa en mensajes de notificación
        // (cron _processWeather); sin este parámetro aparecería en inglés
        // ("Patchy rain possible", "Thundery outbreaks possible") al
        // usuario final.
        params: { key: weatherConfig.WEATHER_API_KEY, q: locationKey, days, aqi: 'no', lang: 'es' },
        timeout: 8000,
      });

      const { current: c, forecast: f } = response.data;

      const current: WeatherConditionData = {
        temperature:     c.temp_c,
        feelsLike:       c.feelslike_c,
        humidity:        c.humidity,
        windSpeed:       c.wind_kph,
        condition:       c.condition.text,
        icon:            `https:${c.condition.icon}`,
        rainProbability: c.precip_mm > 0 ? 50 : 0,
      };

      // Aplanar los arrays de horas de cada día y limitar al número solicitado
      const allHours: ApiHour[] = f.forecastday.flatMap((day) => day.hour);
      const forecastHours = allHours.slice(0, hours);

      const forecast: WeatherHourData[] = forecastHours.map((h) => ({
        hour:            h.time,
        temperature:     h.temp_c,
        humidity:        h.humidity,
        rainProbability: h.chance_of_rain,
        condition:       h.condition.text,
        willItRain:      h.will_it_rain === 1,
      }));

      logger.debug(`Datos obtenidos de WeatherAPI.com para ${locationKey} (${forecast.length} horas)`);
      return { current, forecast };

    } catch (error) {
      if (error instanceof AxiosError) {
        if (error.response?.status === 429) {
          logger.warn(`WeatherAPI 429 (rate limit) para ${locationKey}`);
          throw new ExternalServiceException('WeatherAPI', '429 rate limit exceeded');
        }
        if (error.response?.status === 401 || error.response?.status === 403) {
          throw new ExternalServiceException('WeatherAPI', 'API key inválida o sin permisos');
        }
      }
      const msg = error instanceof Error ? error.message : String(error);
      logger.error(`Error en WeatherAPIDataSource: ${msg}`);
      throw new ExternalServiceException('WeatherAPI', msg);
    }
  }

  /**
   * Obtiene la precipitación total (mm) del día anterior para una localización.
   * En MOCK_WEATHER_MODE devuelve un valor fijo (8mm) para demos reproducibles.
   * En producción consulta history.json de WeatherAPI.com con dt=ayer (YYYY-MM-DD).
   *
   * @param locationKey — Clave normalizada lat,lon.
   * @returns Precipitación total del día anterior en mm (0 si no llovió).
   * @throws {ExternalServiceException} Si la API devuelve error no recuperable.
   */
  async fetchYesterdayRainfall(locationKey: string): Promise<number> {
    if (weatherConfig.MOCK_WEATHER_MODE) {
      logger.debug(`MOCK_WEATHER_MODE activo — devolviendo lluvia simulada para ${locationKey}`);
      return 8;
    }

    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    const dt = yesterday.toISOString().slice(0, 10);

    try {
      const url = `${weatherConfig.WEATHER_API_URL}/history.json`;
      const response = await axios.get<ApiHistoryResponse>(url, {
        // lang=es por coherencia con forecast.json: aunque history.json solo
        // se use para totalprecip_mm numérico, mantener el parámetro previene
        // regresión si en el futuro se empieza a leer condition.text del
        // histórico.
        params: { key: weatherConfig.WEATHER_API_KEY, q: locationKey, dt, lang: 'es' },
        timeout: 8000,
      });

      const mm = response.data.forecast.forecastday[0]?.day.totalprecip_mm ?? 0;
      logger.debug(`Lluvia ayer en ${locationKey}: ${mm}mm (${dt})`);
      return mm;

    } catch (error) {
      if (error instanceof AxiosError) {
        if (error.response?.status === 429) {
          throw new ExternalServiceException('WeatherAPI', '429 rate limit exceeded');
        }
        if (error.response?.status === 401 || error.response?.status === 403) {
          throw new ExternalServiceException('WeatherAPI', 'API key inválida o sin permisos');
        }
      }
      const msg = error instanceof Error ? error.message : String(error);
      logger.error(`Error en fetchYesterdayRainfall: ${msg}`);
      throw new ExternalServiceException('WeatherAPI', msg);
    }
  }
}
