/**
 * @file CreatePlantUseCase.ts
 * @description Caso de uso para crear una nueva planta.
 * Calcula nextWatering y opcionalmente nextPruning antes de persistir.
 * @module Plants
 * @layer Domain
 *
 * @implements {ICreatePlantUseCase}
 * @injectable
 * @dependencies IPlantRepository, IPlantMapper
 */

import { injectable, inject } from 'inversify';
import { TYPES } from '../../../core/types.js';
import type { ICreatePlantUseCase } from '../../interfaces/usecases/plants/ICreatePlantUseCase.js';
import type { IPlantRepository } from '../../repositories/IPlantRepository.js';
import type { IPlantSpeciesRepository } from '../../repositories/IPlantSpeciesRepository.js';
import type { IPlantMapper } from '../../../data/IMappers/IPlantMapper.js';
import type { CreatePlantRequestDTO } from '../../dtos/plants/create-plant-request.dto.js';
import type { PlantResponseDTO } from '../../dtos/plants/plant-response.dto.js';
import { Plant } from '../../entities/Plant.js';
import { NotFoundException } from '../../../core/exceptions/NotFoundException.js';

/**
 * Crea una nueva planta para el usuario autenticado.
 * Calcula nextWatering y nextPruning a partir de las frecuencias indicadas.
 *
 * @implements {ICreatePlantUseCase}
 * @injectable
 * @dependencies IPlantRepository, IPlantSpeciesRepository, IPlantMapper
 */
@injectable()
export class CreatePlantUseCase implements ICreatePlantUseCase {
  constructor(
    @inject(TYPES.IPlantRepository)        private readonly plantRepo:    IPlantRepository,
    @inject(TYPES.IPlantSpeciesRepository) private readonly speciesRepo:  IPlantSpeciesRepository,
    @inject(TYPES.IPlantMapper)            private readonly mapper:       IPlantMapper,
  ) {}

  /**
   * @param dto — Datos validados de la planta a crear.
   * @param userId — Id del usuario propietario.
   * @returns PlantResponseDTO de la planta creada.
   */
  async execute(dto: CreatePlantRequestDTO, userId: string): Promise<PlantResponseDTO> {
    const now = new Date();

    // Validar que la especie existe antes de crear la planta.
    const species = await this.speciesRepo.findById(dto.speciesId);
    if (!species) {
      throw new NotFoundException(`Species not found: ${dto.speciesId}`);
    }

    // Construir entidad temporal para calcular nextWatering/nextPruning
    const tempPlant = new Plant({
      id:                        '',
      userId,
      name:                      dto.name,
      speciesId:                 dto.speciesId,
      photo:                     dto.photo,
      location:                  dto.location,
      plantLocation:             dto.plantLocation,
      plantLocationLat:          dto.plantLocationLat,
      plantLocationLon:          dto.plantLocationLon,
      wateringFrequency:         dto.wateringFrequency,
      lightNeed:                 dto.lightNeed,
      pruningFrequency:          dto.pruningFrequency,
      notes:                     dto.notes,
      considerWeatherForWatering: dto.considerWeatherForWatering ?? false,
      createdAt:                 now,
      updatedAt:                 now,
    });

    const nextWatering = tempPlant.calculateNextWatering(now);
    const nextPruning  = tempPlant.calculateNextPruning(now);

    // TFG: cast necesario porque Omit<Plant,'id'> incluye métodos de clase
    // que el plain object no implementa; el mapper se encarga de la conversión real.
    const created = await this.plantRepo.create({
      userId,
      name:                      dto.name,
      speciesId:                 dto.speciesId,
      photo:                     dto.photo,
      location:                  dto.location,
      plantLocation:             dto.plantLocation,
      plantLocationLat:          dto.plantLocationLat,
      plantLocationLon:          dto.plantLocationLon,
      wateringFrequency:         dto.wateringFrequency,
      lightNeed:                 dto.lightNeed,
      pruningFrequency:          dto.pruningFrequency,
      notes:                     dto.notes,
      nextWatering,
      nextPruning,
      considerWeatherForWatering: dto.considerWeatherForWatering ?? false,
      overrides:                 [],
      createdAt:                 now,
      updatedAt:                 now,
    } as unknown as Omit<Plant, 'id'>);

    return this.mapper.toResponseDTO(created);
  }
}
