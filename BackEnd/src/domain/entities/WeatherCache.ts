/**
 * @file WeatherCache.ts
 * @description Entidad de dominio que representa los datos meteorológicos en caché.
 * Almacena condiciones actuales y previsión horaria para una localización dada.
 * La clave de localización normaliza lat/lon para compartir caché entre usuarios.
 * @module Weather
 * @layer Domain
 */

/**
 * Condiciones meteorológicas actuales.
 */
export interface WeatherConditionData {
  /** Temperatura en grados Celsius */
  temperature: number;
  /** Sensación térmica en grados Celsius */
  feelsLike: number;
  /** Humedad relativa (0–100 %) */
  humidity: number;
  /** Velocidad del viento en km/h */
  windSpeed: number;
  /** Descripción textual del estado (ej.: "Sunny", "Rainy") */
  condition: string;
  /** URL del icono del estado meteorológico (opcional) */
  icon?: string;
  /** Probabilidad de lluvia (0–100 %) */
  rainProbability: number;
}

/**
 * Datos meteorológicos de una hora concreta del pronóstico.
 */
export interface WeatherHourData {
  /** Fecha/hora en formato ISO 8601 */
  hour: string;
  /** Temperatura en grados Celsius */
  temperature: number;
  /** Humedad relativa (0–100 %) */
  humidity: number;
  /** Probabilidad de lluvia (0–100 %) */
  rainProbability: number;
  /** Descripción textual del estado */
  condition: string;
  /** true si se espera lluvia en esa hora */
  willItRain: boolean;
}

/**
 * Contenido completo almacenado en el campo data de WeatherCache.
 */
export interface WeatherCacheData {
  /** Condiciones actuales */
  current: WeatherConditionData;
  /** Previsión horaria (hasta N horas configurables) */
  forecast: WeatherHourData[];
}

/**
 * Entidad de caché meteorológica.
 * Agrupa condiciones actuales + previsión bajo una clave de localización.
 * La TTL se controla via expiresAt; el repositorio elimina entradas expiradas.
 */
export class WeatherCache {
  readonly id:          string;
  readonly locationKey: string;
  readonly data:        WeatherCacheData;
  readonly fetchedAt:   Date;
  readonly expiresAt:   Date;

  constructor(params: {
    id:          string;
    locationKey: string;
    data:        WeatherCacheData;
    fetchedAt:   Date;
    expiresAt:   Date;
  }) {
    this.id          = params.id;
    this.locationKey = params.locationKey;
    this.data        = params.data;
    this.fetchedAt   = params.fetchedAt;
    this.expiresAt   = params.expiresAt;
  }

  /**
   * true si la caché ha expirado en el momento dado.
   *
   * @param now — Fecha de referencia (por defecto, ahora).
   * @returns boolean
   */
  isExpired(now: Date = new Date()): boolean {
    return this.expiresAt <= now;
  }
}
