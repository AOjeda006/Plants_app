/**
 * @file IDeletePlantUseCase.ts
 * @description Interfaz del caso de uso para eliminar (soft-delete) una planta.
 * @module Plants
 * @layer Domain
 */
export interface IDeletePlantUseCase {
  execute(plantId: string, userId: string): Promise<void>;
}
