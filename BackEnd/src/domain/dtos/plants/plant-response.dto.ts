/**
 * @file plant-response.dto.ts
 * @description DTO de respuesta para una planta. Se serializa y devuelve al cliente.
 * @module Plants
 * @layer Domain
 */

/**
 * DTO de respuesta para una planta.
 * No contiene passwordHash ni datos internos del sistema.
 */
export interface PlantResponseDTO {
  id: string;
  userId: string;
  name: string;
  speciesId?: string;
  photo?: string;
  location: 'Interior' | 'Exterior';
  plantLocation?: string;
  plantLocationLat?: number;
  plantLocationLon?: number;
  wateringFrequency: number;
  lightNeed: 'Low' | 'Medium' | 'High';
  pruningFrequency?: number;
  notes?: string;
  nextWatering?: string;
  nextPruning?: string;
  considerWeatherForWatering: boolean;
  createdAt: string;
  updatedAt: string;
}
