/**
 * @file IGetCurrentWeatherUseCase.ts
 * @description Interfaz del caso de uso para obtener el clima actual de una ubicación.
 * @module Weather
 * @layer Domain
 */

import type { WeatherQueryRequestDTO } from '../../../dtos/weather/weather-query-request.dto.js';
import type { WeatherResponseDTO } from '../../../dtos/weather/weather-response.dto.js';

export interface IGetCurrentWeatherUseCase {
  /**
   * @param dto — Coordenadas de la localización (lat, lon).
   * @returns WeatherResponseDTO con las condiciones actuales.
   * @throws {ValidationException} Si las coordenadas son inválidas.
   * @throws {ExternalServiceException} Si la API no está disponible.
   */
  execute(dto: WeatherQueryRequestDTO): Promise<WeatherResponseDTO>;
}
