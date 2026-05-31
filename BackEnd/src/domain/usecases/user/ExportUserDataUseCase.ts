/**
 * @file ExportUserDataUseCase.ts
 * @description Caso de uso para exportar todos los datos personales de un usuario (RGPD).
 * Agrega perfil y plantas del usuario en un objeto JSON serializable.
 * @module User
 * @layer Domain
 *
 * @implements {IExportUserDataUseCase}
 * @injectable
 * @dependencies IUserRepository, IPlantRepository
 */

import { injectable, inject } from 'inversify';
import { TYPES } from '../../../core/types.js';
import type { IExportUserDataUseCase } from '../../interfaces/usecases/user/IExportUserDataUseCase.js';
import type { IUserRepository } from '../../repositories/IUserRepository.js';
import type { IPlantRepository } from '../../repositories/IPlantRepository.js';
import { NotFoundException } from '../../../core/exceptions/NotFoundException.js';

/**
 * Exporta los datos personales del usuario autenticado en formato JSON.
 * Incluye perfil completo y lista de plantas. Conforme a RGPD.
 *
 * @implements {IExportUserDataUseCase}
 * @injectable
 * @dependencies IUserRepository, IPlantRepository
 */
@injectable()
export class ExportUserDataUseCase implements IExportUserDataUseCase {
  constructor(
    @inject(TYPES.IUserRepository)  private readonly userRepo:  IUserRepository,
    @inject(TYPES.IPlantRepository) private readonly plantRepo: IPlantRepository,
  ) {}

  /**
   * @param userId — ID del usuario autenticado.
   * @returns JSON con perfil, plantas y timestamp de exportación.
   * @throws {NotFoundException} Si el usuario no existe.
   */
  async execute(userId: string): Promise<Record<string, unknown>> {
    const user = await this.userRepo.findById(userId);
    if (!user) throw new NotFoundException('User', userId);

    const plants = await this.plantRepo.findByUserId(userId);

    return {
      exportedAt: new Date().toISOString(),
      profile: {
        id:          user.id,
        name:        user.name,
        email:       user.email,
        bio:         user.bio          ?? null,
        location:    user.location     ?? null,
        photo:       user.photo        ?? null,
        preferences: user.preferences  ?? {},
        createdAt:   user.createdAt,
      },
      plants: plants.map(p => ({
        id:               p.id,
        name:             p.name,
        speciesId:        p.speciesId     ?? null,
        location:         p.location,
        lightNeed:        p.lightNeed,
        wateringFrequency: p.wateringFrequency,
        notes:            p.notes         ?? null,
        photo:            p.photo         ?? null,
        nextWatering:     p.nextWatering  ?? null,
        createdAt:        p.createdAt,
      })),
      totalPlants: plants.length,
    };
  }
}
