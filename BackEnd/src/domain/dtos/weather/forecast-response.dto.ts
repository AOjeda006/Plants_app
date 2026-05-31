/**
 * @file forecast-response.dto.ts
 * @description DTOs de respuesta para la previsión meteorológica por horas.
 * @module Weather
 * @layer Domain
 */

/**
 * Datos meteorológicos de una hora concreta en el pronóstico.
 */
export interface WeatherHourDTO {
  /** Fecha/hora en formato ISO 8601 */
  hour: string;
  /** Temperatura en grados Celsius */
  temperature: number;
  /** Humedad relativa (0–100 %) */
  humidity: number;
  /** Probabilidad de lluvia (0–100 %) */
  rainProbability: number;
  /** Descripción del estado */
  condition: string;
  /** true si se espera lluvia en esa hora */
  willItRain: boolean;
}

/**
 * DTO de respuesta para el endpoint GET /weather/forecast.
 */
export interface ForecastResponseDTO {
  /** Clave normalizada de la localización */
  locationKey: string;
  /** Lista de condiciones por hora */
  hours: WeatherHourDTO[];
  /** Momento en que se obtuvieron los datos */
  fetchedAt: string;
}
