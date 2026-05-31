/**
 * @file IUpdatePlantUseCase.ts
 * @description Interfaz del caso de uso para actualizar una planta.
 * @module Plants
 * @layer Domain
 */

import type { UpdatePlantRequestDTO } from '../../../dtos/plants/update-plant-request.dto.js';
import type { PlantResponseDTO } from '../../../dtos/plants/plant-response.dto.js';

export interface IUpdatePlantUseCase {
  /**
   * @param plantId — Id de la planta a actualizar.
   * @param dto — Campos a actualizar (todos opcionales).
   * @param userId — Id del usuario (para verificar ownership).
   * @returns Planta actualizada como DTO de respuesta.
   * @throws {NotFoundException} Si la planta no existe.
   * @throws {UnauthorizedException} Si el usuario no es propietario.
   */
  execute(plantId: string, dto: UpdatePlantRequestDTO, userId: string): Promise<PlantResponseDTO>;
}
