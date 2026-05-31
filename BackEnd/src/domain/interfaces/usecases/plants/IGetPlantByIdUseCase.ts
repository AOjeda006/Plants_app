/**
 * @file IGetPlantByIdUseCase.ts
 * @description Interfaz del caso de uso para obtener una planta por ID.
 * @module Plants
 * @layer Domain
 */

import type { PlantResponseDTO } from '../../../dtos/plants/plant-response.dto.js';

export interface IGetPlantByIdUseCase {
  /**
   * @param plantId — Id de la planta.
   * @param userId — Id del usuario (para verificar ownership).
   * @returns Planta como DTO de respuesta.
   * @throws {NotFoundException} Si la planta no existe.
   * @throws {UnauthorizedException} Si el usuario no es propietario.
   */
  execute(plantId: string, userId: string): Promise<PlantResponseDTO>;
}
