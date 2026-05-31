/**
 * @file GetUserPlantsUseCase.ts
 * @description Caso de uso para obtener la lista de plantas del usuario autenticado.
 * Calcula nextWatering actualizado antes de mapear al DTO de respuesta.
 * @module Plants
 * @layer Domain
 *
 * @implements {IGetUserPlantsUseCase}
 * @injectable
 * @dependencies IPlantRepository, IPlantMapper
 */

import { injectable, inject } from 'inversify';
import { TYPES } from '../../../core/types.js';
import type { IGetUserPlantsUseCase } from '../../interfaces/usecases/plants/IGetUserPlantsUseCase.js';
import type { IPlantRepository } from '../../repositories/IPlantRepository.js';
import type { IPlantMapper } from '../../../data/IMappers/IPlantMapper.js';
import type { PlantResponseDTO } from '../../dtos/plants/plant-response.dto.js';

/**
 * Obtiene todas las plantas activas del usuario.
 *
 * @implements {IGetUserPlantsUseCase}
 * @injectable
 * @dependencies IPlantRepository, IPlantMapper
 */
@injectable()
export class GetUserPlantsUseCase implements IGetUserPlantsUseCase {
  constructor(
    @inject(TYPES.IPlantRepository) private readonly plantRepo: IPlantRepository,
    @inject(TYPES.IPlantMapper)     private readonly mapper: IPlantMapper,
  ) {}

  /**
   * Retorna las plantas del usuario, con nextWatering recalculado si es necesario.
   *
   * @param userId — Id del usuario autenticado.
   * @returns Lista de PlantResponseDTO.
   */
  async execute(userId: string): Promise<PlantResponseDTO[]> {
    const plants = await this.plantRepo.findByUserId(userId);
    return plants.map((plant) => this.mapper.toResponseDTO(plant));
  }
}
