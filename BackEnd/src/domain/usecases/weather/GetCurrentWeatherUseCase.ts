/**
 * @file GetCurrentWeatherUseCase.ts
 * @description Caso de uso para obtener el clima actual de una localización.
 * Delega en WeatherService la lógica de caché + API.
 * @module Weather
 * @layer Domain
 *
 * @implements {IGetCurrentWeatherUseCase}
 * @injectable
 * @dependencies WeatherService
 */

import { injectable, inject } from 'inversify';
import { TYPES } from '../../../core/types.js';
import type { IGetCurrentWeatherUseCase } from '../../interfaces/usecases/weather/IGetCurrentWeatherUseCase.js';
import type { WeatherQueryRequestDTO } from '../../dtos/weather/weather-query-request.dto.js';
import type { WeatherResponseDTO } from '../../dtos/weather/weather-response.dto.js';
import { WeatherService } from '../../../presentation/services/WeatherService.js';

/**
 * Obtiene el clima actual para las coordenadas dadas.
 *
 * @implements {IGetCurrentWeatherUseCase}
 * @injectable
 * @dependencies WeatherService
 */
@injectable()
export class GetCurrentWeatherUseCase implements IGetCurrentWeatherUseCase {
  constructor(
    @inject(TYPES.WeatherService) private readonly weatherService: WeatherService,
  ) {}

  /**
   * @param dto — Localización como string libre (`location`) o coordenadas (`lat`/`lon`).
   *              Si se proporciona `location`, tiene prioridad sobre lat/lon.
   * @returns WeatherResponseDTO con las condiciones actuales.
   * @throws {ExternalServiceException} Si la API no está disponible.
   */
  async execute(dto: WeatherQueryRequestDTO): Promise<WeatherResponseDTO> {
    if (dto.location?.trim()) {
      return this.weatherService.getWeatherForQuery(dto.location.trim());
    }
    return this.weatherService.getWeatherForLocation(dto.lat!, dto.lon!);
  }
}
