/**
 * @file GetPlantByIdUseCase.ts
 * @description Caso de uso para obtener una planta por ID con verificación de ownership.
 * @module Plants
 * @layer Domain
 *
 * @implements {IGetPlantByIdUseCase}
 * @injectable
 * @dependencies IPlantRepository, IPlantMapper
 */

import { injectable, inject } from 'inversify';
import { TYPES } from '../../../core/types.js';
import type { IGetPlantByIdUseCase } from '../../interfaces/usecases/plants/IGetPlantByIdUseCase.js';
import type { IPlantRepository } from '../../repositories/IPlantRepository.js';
import type { IPlantMapper } from '../../../data/IMappers/IPlantMapper.js';
import type { PlantResponseDTO } from '../../dtos/plants/plant-response.dto.js';
import { NotFoundException } from '../../../core/exceptions/NotFoundException.js';
import { verifyOwnership } from '../../../presentation/validators/ownershipValidator.js';

/**
 * Obtiene una planta por ID verificando que el usuario sea propietario.
 *
 * @implements {IGetPlantByIdUseCase}
 * @injectable
 * @dependencies IPlantRepository, IPlantMapper
 */
@injectable()
export class GetPlantByIdUseCase implements IGetPlantByIdUseCase {
  constructor(
    @inject(TYPES.IPlantRepository) private readonly plantRepo: IPlantRepository,
    @inject(TYPES.IPlantMapper)     private readonly mapper: IPlantMapper,
  ) {}

  /**
   * @param plantId — Id de la planta.
   * @param userId — Id del usuario autenticado.
   * @returns PlantResponseDTO.
   * @throws {NotFoundException} Si la planta no existe.
   * @throws {UnauthorizedException} Si el usuario no es propietario.
   */
  async execute(plantId: string, userId: string): Promise<PlantResponseDTO> {
    const plant = await this.plantRepo.findById(plantId);

    if (!plant || plant.deletedAt) throw new NotFoundException('Plant', plantId);

    verifyOwnership(plant.userId, userId, 'Plant');

    return this.mapper.toResponseDTO(plant);
  }
}
