/**
 * @file PlantController.ts
 * @description Controlador HTTP de plantas del usuario.
 * Depende exclusivamente de interfaces de use cases, nunca de implementaciones concretas.
 * @module Plants
 * @layer Presentation
 *
 * @injectable
 * @dependencies IGetUserPlantsUseCase, IGetPlantByIdUseCase, ICreatePlantUseCase, IUpdatePlantUseCase, IDeletePlantUseCase
 */

import { injectable, inject } from 'inversify';
import { Request, Response, NextFunction, Router } from 'express';
import { AuthenticatedRequest } from '../../core/middleware/AuthMiddleware.js';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import type { IGetUserPlantsUseCase } from '../../domain/interfaces/usecases/plants/IGetUserPlantsUseCase.js';
import type { IGetPlantByIdUseCase } from '../../domain/interfaces/usecases/plants/IGetPlantByIdUseCase.js';
import type { ICreatePlantUseCase } from '../../domain/interfaces/usecases/plants/ICreatePlantUseCase.js';
import type { IUpdatePlantUseCase } from '../../domain/interfaces/usecases/plants/IUpdatePlantUseCase.js';
import type { IDeletePlantUseCase } from '../../domain/interfaces/usecases/plants/IDeletePlantUseCase.js';
import { CreatePlantRequestDTO } from '../../domain/dtos/plants/create-plant-request.dto.js';
import { UpdatePlantRequestDTO } from '../../domain/dtos/plants/update-plant-request.dto.js';
import { TYPES } from '../../core/types.js';
import { ValidationException, ValidationError } from '../../core/exceptions/ValidationException.js';
import { createLogger } from '../../core/logger.js';

const logger = createLogger('PlantController');

/**
 * Valida un DTO con class-validator y lanza ValidationException si hay errores.
 * @private
 */
async function validateDTO<T extends object>(DtoClass: new () => T, body: unknown): Promise<T> {
  const instance = plainToInstance(DtoClass, body);
  const errors = await validate(instance as object);
  if (errors.length > 0) {
    const validationErrors: ValidationError[] = errors.map(e => ({
      field: e.property,
      message: Object.values(e.constraints ?? {}).join(', '),
    }));
    throw new ValidationException(validationErrors);
  }
  return instance;
}

/**
 * Controlador de rutas de plantas.
 *
 * @injectable
 * @dependencies IGetUserPlantsUseCase, IGetPlantByIdUseCase, ICreatePlantUseCase, IUpdatePlantUseCase, IDeletePlantUseCase
 */
@injectable()
export class PlantController {
  constructor(
    @inject(TYPES.IGetUserPlantsUseCase) private readonly getUserPlants: IGetUserPlantsUseCase,
    @inject(TYPES.IGetPlantByIdUseCase)  private readonly getPlantById: IGetPlantByIdUseCase,
    @inject(TYPES.ICreatePlantUseCase)   private readonly createPlant: ICreatePlantUseCase,
    @inject(TYPES.IUpdatePlantUseCase)   private readonly updatePlant: IUpdatePlantUseCase,
    @inject(TYPES.IDeletePlantUseCase)   private readonly deletePlant: IDeletePlantUseCase,
  ) {}

  /**
   * Devuelve un Router de Express con todas las rutas de plantas.
   * Usar en bootstrap(): app.use('/plants', plantController.router()).
   */
  router(): Router {
    const router = Router();
    router.get('/',           this.handleGetAll.bind(this));
    router.get('/:id',        this.handleGetById.bind(this));
    router.post('/',          this.handleCreate.bind(this));
    router.put('/:id',        this.handleUpdate.bind(this));
    router.delete('/:id',     this.handleDelete.bind(this));
    // Ruta de riego manual: calcula nextWatering y registra lastWatered en el servidor.
    router.post('/:id/water', this.handleWaterPlant.bind(this));
    return router;
  }

  /**
   * GET /plants — Lista todas las plantas del usuario autenticado.
   *
   * @param req — Request con req.user.id del AuthMiddleware.
   * @param res — Response con array de PlantResponseDTO.
   * @param next — Manejador de errores.
   */
  private async handleGetAll(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = (req as AuthenticatedRequest).user.userId;
      const plants = await this.getUserPlants.execute(userId);
      res.json(plants);
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /plants/:id — Detalle de una planta (verifica ownership).
   *
   * @param req — Request con req.params['id'] as string y req.user.id.
   * @param res — Response con PlantResponseDTO.
   * @param next — Manejador de errores.
   */
  private async handleGetById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = (req as AuthenticatedRequest).user.userId;
      const plant = await this.getPlantById.execute(req.params['id'] as string, userId);
      res.json(plant);
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /plants — Crea una nueva planta.
   *
   * @param req — Request con body JSON (CreatePlantRequestDTO).
   * @param res — Response 201 con PlantResponseDTO.
   * @param next — Manejador de errores.
   */
  private async handleCreate(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = (req as AuthenticatedRequest).user.userId;
      const dto = await validateDTO(CreatePlantRequestDTO, req.body);
      const plant = await this.createPlant.execute(dto, userId);
      res.status(201).json(plant);
      logger.info(`Planta creada por usuario ${userId}: ${plant.id}`);
    } catch (error) {
      next(error);
    }
  }

  /**
   * PUT /plants/:id — Actualiza una planta existente (PATCH semantics).
   *
   * @param req — Request con req.params['id'] as string y body JSON (UpdatePlantRequestDTO).
   * @param res — Response con PlantResponseDTO actualizado.
   * @param next — Manejador de errores.
   */
  private async handleUpdate(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = (req as AuthenticatedRequest).user.userId;
      const dto = await validateDTO(UpdatePlantRequestDTO, req.body);
      const plant = await this.updatePlant.execute(req.params['id'] as string, dto, userId);
      res.json(plant);
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /plants/:id/water — Registra un riego manual de la planta.
   * Recalcula nextWatering = hoy + wateringFrequency y guarda lastWatered = ahora.
   *
   * @param req — Request con req.params['id'] y req.user.id.
   * @param res — Response con PlantResponseDTO actualizado.
   * @param next — Manejador de errores.
   */
  private async handleWaterPlant(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId  = (req as AuthenticatedRequest).user.userId;
      const plantId = req.params['id'] as string;

      // Obtener la planta para verificar ownership y leer wateringFrequency actual.
      const plant = await this.getPlantById.execute(plantId, userId);

      // Pasar wateringFrequency actual para forzar el recálculo de nextWatering en el use case.
      const dto = new UpdatePlantRequestDTO();
      dto.wateringFrequency = plant.wateringFrequency;
      dto.lastWatered       = new Date().toISOString();

      const updated = await this.updatePlant.execute(plantId, dto, userId);
      res.json(updated);
      logger.info(`Planta regada manualmente por usuario ${userId}: ${plantId}`);
    } catch (error) {
      next(error);
    }
  }

  /**
   * DELETE /plants/:id — Elimina (soft delete) una planta.
   *
   * @param req — Request con req.params['id'] as string y req.user.id.
   * @param res — Response 204 sin cuerpo.
   * @param next — Manejador de errores.
   */
  private async handleDelete(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = (req as AuthenticatedRequest).user.userId;
      await this.deletePlant.execute(req.params['id'] as string, userId);
      res.status(204).send();
      logger.info(`Planta eliminada por usuario ${userId}: ${req.params['id'] as string}`);
    } catch (error) {
      next(error);
    }
  }
}
