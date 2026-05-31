/**
 * @file ISearchSpeciesUseCase.ts
 * @description Interfaz del caso de uso para buscar especies de plantas.
 * @module Plants
 * @layer Domain
 */

import type { PlantSpeciesResponseDTO } from '../../../dtos/plants/plant-species-response.dto.js';

export interface ISearchSpeciesUseCase {
  /**
   * @param query — Texto de búsqueda (nombre o nombre científico).
   * @returns Lista de especies públicas coincidentes como DTOs.
   */
  execute(query: string): Promise<PlantSpeciesResponseDTO[]>;
}
