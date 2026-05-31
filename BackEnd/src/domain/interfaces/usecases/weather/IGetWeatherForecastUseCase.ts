/**
 * @file IGetWeatherForecastUseCase.ts
 * @description Interfaz del caso de uso para obtener la previsión meteorológica por horas.
 * @module Weather
 * @layer Domain
 */

import type { WeatherQueryRequestDTO } from '../../../dtos/weather/weather-query-request.dto.js';
import type { ForecastResponseDTO } from '../../../dtos/weather/forecast-response.dto.js';

export interface IGetWeatherForecastUseCase {
  /**
   * @param dto — Coordenadas y horas de previsión solicitadas.
   * @returns ForecastResponseDTO con la lista de condiciones horarias.
   * @throws {ValidationException} Si las coordenadas o el rango de horas son inválidos.
   * @throws {ExternalServiceException} Si la API no está disponible.
   */
  execute(dto: WeatherQueryRequestDTO): Promise<ForecastResponseDTO>;
}
