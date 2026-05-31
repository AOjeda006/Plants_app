/**
 * @file SearchSpeciesUseCase.ts
 * @description Caso de uso para buscar especies de plantas por texto libre.
 * Solo devuelve especies públicas (isPublic=true).
 * @module Plants
 * @layer Domain
 *
 * @implements {ISearchSpeciesUseCase}
 * @injectable
 * @dependencies IPlantSpeciesRepository, IPlantSpeciesMapper
 */

import { injectable, inject } from 'inversify';
import { TYPES } from '../../../core/types.js';
import type { ISearchSpeciesUseCase } from '../../interfaces/usecases/plants/ISearchSpeciesUseCase.js';
import type { IPlantSpeciesRepository } from '../../repositories/IPlantSpeciesRepository.js';
import type { IPlantSpeciesMapper } from '../../../data/IMappers/IPlantSpeciesMapper.js';
import type { PlantSpeciesResponseDTO } from '../../dtos/plants/plant-species-response.dto.js';

/**
 * Busca especies de plantas por nombre o nombre científico.
 *
 * @implements {ISearchSpeciesUseCase}
 * @injectable
 * @dependencies IPlantSpeciesRepository, IPlantSpeciesMapper
 */
@injectable()
export class SearchSpeciesUseCase implements ISearchSpeciesUseCase {
  constructor(
    @inject(TYPES.IPlantSpeciesRepository) private readonly speciesRepo: IPlantSpeciesRepository,
    @inject(TYPES.IPlantSpeciesMapper)     private readonly mapper: IPlantSpeciesMapper,
  ) {}

  /**
   * @param query — Texto de búsqueda (mínimo 1 carácter).
   * @returns Lista de PlantSpeciesResponseDTO coincidentes.
   */
  async execute(query: string): Promise<PlantSpeciesResponseDTO[]> {
    // Query vacío = devolver todas las especies públicas (para autocompletado inicial).
    const species = await this.speciesRepo.search(query.trim());
    return species.map((s) => this.mapper.toResponseDTO(s));
  }
}
