/**
 * @file DeletePlantUseCase.ts
 * @description Caso de uso para eliminar (soft delete) una planta del usuario.
 * @module Plants
 * @layer Domain
 *
 * @implements {IDeletePlantUseCase}
 * @injectable
 * @dependencies IPlantRepository
 */

import { injectable, inject } from 'inversify';
import { TYPES } from '../../../core/types.js';
import type { IDeletePlantUseCase } from '../../interfaces/usecases/plants/IDeletePlantUseCase.js';
import type { IPlantRepository } from '../../repositories/IPlantRepository.js';
import { NotFoundException } from '../../../core/exceptions/NotFoundException.js';
import { verifyOwnership } from '../../../presentation/validators/ownershipValidator.js';

/**
 * Elimina una planta por soft delete verificando ownership.
 *
 * @implements {IDeletePlantUseCase}
 * @injectable
 * @dependencies IPlantRepository
 */
@injectable()
export class DeletePlantUseCase implements IDeletePlantUseCase {
  constructor(
    @inject(TYPES.IPlantRepository) private readonly plantRepo: IPlantRepository,
  ) {}

  /**
   * @param plantId — Id de la planta a eliminar.
   * @param userId — Id del usuario autenticado.
   * @throws {NotFoundException} Si la planta no existe.
   * @throws {UnauthorizedException} Si el usuario no es propietario.
   */
  async execute(plantId: string, userId: string): Promise<void> {
    const plant = await this.plantRepo.findById(plantId);

    if (!plant || plant.deletedAt) throw new NotFoundException('Plant', plantId);

    verifyOwnership(plant.userId, userId, 'Plant');

    await this.plantRepo.delete(plantId, true);
  }
}
