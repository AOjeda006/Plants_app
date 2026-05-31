/**
 * @file ICreatePlantUseCase.ts
 * @description Interfaz del caso de uso para crear una planta.
 * @module Plants
 * @layer Domain
 */

import type { CreatePlantRequestDTO } from '../../../dtos/plants/create-plant-request.dto.js';
import type { PlantResponseDTO } from '../../../dtos/plants/plant-response.dto.js';

export interface ICreatePlantUseCase {
  /**
   * @param dto — Datos de la planta a crear.
   * @param userId — Id del usuario propietario.
   * @returns Planta creada como DTO de respuesta.
   */
  execute(dto: CreatePlantRequestDTO, userId: string): Promise<PlantResponseDTO>;
}
