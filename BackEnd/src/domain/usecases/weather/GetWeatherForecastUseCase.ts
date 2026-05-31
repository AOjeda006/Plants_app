/**
 * @file GetWeatherForecastUseCase.ts
 * @description Caso de uso para obtener la previsión meteorológica por horas.
 * Delega en WeatherService la lógica de caché + API.
 * @module Weather
 * @layer Domain
 *
 * @implements {IGetWeatherForecastUseCase}
 * @injectable
 * @dependencies WeatherService
 */

import { injectable, inject } from 'inversify';
import { TYPES } from '../../../core/types.js';
import type { IGetWeatherForecastUseCase } from '../../interfaces/usecases/weather/IGetWeatherForecastUseCase.js';
import type { WeatherQueryRequestDTO } from '../../dtos/weather/weather-query-request.dto.js';
import type { ForecastResponseDTO } from '../../dtos/weather/forecast-response.dto.js';
import { WeatherService } from '../../../presentation/services/WeatherService.js';

/**
 * Obtiene la previsión horaria para las coordenadas dadas.
 *
 * @implements {IGetWeatherForecastUseCase}
 * @injectable
 * @dependencies WeatherService
 */
@injectable()
export class GetWeatherForecastUseCase implements IGetWeatherForecastUseCase {
  constructor(
    @inject(TYPES.WeatherService) private readonly weatherService: WeatherService,
  ) {}

  /**
   * @param dto — Localización como string libre (`location`) o coordenadas (`lat`/`lon`),
   *              más número de horas opcionales.
   * @returns ForecastResponseDTO con la lista de condiciones horarias.
   * @throws {ExternalServiceException} Si la API no está disponible.
   */
  async execute(dto: WeatherQueryRequestDTO): Promise<ForecastResponseDTO> {
    if (dto.location?.trim()) {
      return this.weatherService.getForecastForQuery(dto.location.trim(), dto.hours ?? 24);
    }
    return this.weatherService.getForecast(dto.lat!, dto.lon!, dto.hours ?? 24);
  }
}
