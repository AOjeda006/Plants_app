/**
 * @file IGetUserPlantsUseCase.ts
 * @description Interfaz del caso de uso para obtener todas las plantas del usuario.
 * @module Plants
 * @layer Domain
 */

import type { PlantResponseDTO } from '../../../dtos/plants/plant-response.dto.js';

export interface IGetUserPlantsUseCase {
  /**
   * @param userId — Id del usuario autenticado.
   * @returns Lista de plantas del usuario como DTOs de respuesta.
   */
  execute(userId: string): Promise<PlantResponseDTO[]>;
}
