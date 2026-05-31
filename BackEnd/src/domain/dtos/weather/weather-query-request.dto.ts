/**
 * @file weather-query-request.dto.ts
 * @description DTO de entrada para consultas meteorológicas.
 * Recibe coordenadas geográficas y número de horas de previsión.
 * @module Weather
 * @layer Domain
 */

import { IsNumber, IsOptional, IsString, Min, Max } from 'class-validator';
import { Type } from 'class-transformer';

/**
 * DTO validado para peticiones de clima actual y previsión.
 *
 * Acepta dos formatos de localización (al menos uno es obligatorio):
 *  - `location` — string libre que WeatherAPI.com pueda resolver: nombre de ciudad
 *    ("Sevilla", "Madrid, Spain"), coordenadas ("37.39,-5.99"), código postal, etc.
 *  - `lat` + `lon` — coordenadas decimales (formato legado / GPS).
 *
 * Si se envían ambos, `location` tiene prioridad.
 */
export class WeatherQueryRequestDTO {
  /**
   * Localización en formato string libre (ciudad, coordenadas, código postal…).
   * WeatherAPI.com acepta cualquier valor que su endpoint de búsqueda resuelva.
   * Ejemplos: "Sevilla", "Madrid, Spain", "37.39,-5.99", "28080".
   */
  @IsOptional()
  @IsString()
  location?: string;

  /** Latitud en grados decimales (-90 a 90) — alternativa a location. */
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(-90)
  @Max(90)
  lat?: number;

  /** Longitud en grados decimales (-180 a 180) — alternativa a location. */
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(-180)
  @Max(180)
  lon?: number;

  /** Horas de previsión solicitadas (1–48; por defecto 24). */
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(1)
  @Max(48)
  hours?: number;
}
