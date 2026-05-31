/**
 * @file weather-response.dto.ts
 * @description DTO de respuesta para el clima actual de una localización.
 * @module Weather
 * @layer Domain
 */

/**
 * DTO de respuesta para el endpoint GET /weather.
 */
export interface WeatherResponseDTO {
  /** Clave normalizada de la localización (lat,lon con 4 decimales) */
  locationKey: string;
  /** Temperatura actual en grados Celsius */
  temperature: number;
  /** Sensación térmica en grados Celsius */
  feelsLike: number;
  /** Humedad relativa (0–100 %) */
  humidity: number;
  /** Velocidad del viento en km/h */
  windSpeed: number;
  /** Descripción del estado (ej.: "Sunny", "Partly cloudy") */
  condition: string;
  /** URL del icono del estado meteorológico (puede ser relativa) */
  icon?: string;
  /** Probabilidad de lluvia (0–100 %) */
  rainProbability: number;
  /** Momento en que se obtuvieron los datos */
  fetchedAt: string;
}
