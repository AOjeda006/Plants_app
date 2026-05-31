/**
 * @file WeatherController.ts
 * @description Controlador HTTP de meteorología.
 * Actúa como proxy entre el frontend y WeatherAPI.com.
 * Expone el clima actual y la previsión horaria para una localización.
 * El API key nunca se expone al cliente.
 * @module Weather
 * @layer Presentation
 *
 * @injectable
 * @dependencies IGetCurrentWeatherUseCase, IGetWeatherForecastUseCase
 */

import { injectable, inject } from 'inversify';
import { Request, Response, NextFunction, Router } from 'express';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import type { IGetCurrentWeatherUseCase } from '../../domain/interfaces/usecases/weather/IGetCurrentWeatherUseCase.js';
import type { IGetWeatherForecastUseCase } from '../../domain/interfaces/usecases/weather/IGetWeatherForecastUseCase.js';
import { WeatherQueryRequestDTO } from '../../domain/dtos/weather/weather-query-request.dto.js';
import { TYPES } from '../../core/types.js';
import { ValidationException, ValidationError } from '../../core/exceptions/ValidationException.js';
import { createLogger } from '../../core/logger.js';

const logger = createLogger('WeatherController');

/**
 * Valida un DTO de query params con class-validator.
 * @private
 */
async function validateQueryDTO<T extends object>(DtoClass: new () => T, query: unknown): Promise<T> {
  const instance = plainToInstance(DtoClass, query);
  const errors   = await validate(instance as object);
  if (errors.length > 0) {
    const validationErrors: ValidationError[] = errors.map((e) => ({
      field:   e.property,
      message: Object.values(e.constraints ?? {}).join(', '),
    }));
    throw new ValidationException(validationErrors);
  }
  return instance;
}

/**
 * Controlador de rutas de meteorología.
 *
 * @injectable
 * @dependencies IGetCurrentWeatherUseCase, IGetWeatherForecastUseCase
 */
@injectable()
export class WeatherController {
  constructor(
    @inject(TYPES.IGetCurrentWeatherUseCase)  private readonly getCurrentWeather: IGetCurrentWeatherUseCase,
    @inject(TYPES.IGetWeatherForecastUseCase) private readonly getWeatherForecast: IGetWeatherForecastUseCase,
  ) {}

  /**
   * Devuelve un Router de Express con todas las rutas de meteorología.
   * Usar en bootstrap(): app.use('/weather', weatherController.router()).
   */
  router(): Router {
    const router = Router();
    router.get('/',         this.handleGetCurrent.bind(this));
    router.get('/forecast', this.handleGetForecast.bind(this));
    return router;
  }

  /**
   * GET /weather?lat=...&lon=...
   * Devuelve el clima actual para las coordenadas dadas.
   *
   * @param req — Request con query params lat, lon.
   * @param res — Response con WeatherResponseDTO.
   * @param next — Manejador de errores.
   */
  private async handleGetCurrent(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const dto    = await validateQueryDTO(WeatherQueryRequestDTO, req.query);
      const result   = await this.getCurrentWeather.execute(dto);
      res.json(result);
      const locLabel = dto.location ?? `${dto.lat},${dto.lon}`;
      logger.debug(`Clima actual devuelto para "${locLabel}"`);
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /weather/forecast?lat=...&lon=...&hours=48
   * Devuelve la previsión horaria para las coordenadas dadas.
   *
   * @param req — Request con query params lat, lon, hours?.
   * @param res — Response con ForecastResponseDTO.
   * @param next — Manejador de errores.
   */
  private async handleGetForecast(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const dto    = await validateQueryDTO(WeatherQueryRequestDTO, req.query);
      const result   = await this.getWeatherForecast.execute(dto);
      res.json(result);
      const locLabel = dto.location ?? `${dto.lat},${dto.lon}`;
      logger.debug(`Previsión devuelta para "${locLabel}" (${dto.hours ?? 24}h)`);
    } catch (error) {
      next(error);
    }
  }
}
