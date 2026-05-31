/**
 * @file plant-species-response.dto.ts
 * @description DTO de respuesta para una especie de planta.
 * @module Plants
 * @layer Domain
 */

/**
 * DTO de respuesta para una especie de planta.
 */
export interface PlantSpeciesResponseDTO {
  id: string;
  name: string;
  scientificName: string;
  image?: string;
  careRequirements: {
    wateringDays: number;
    lightNeed: 'Low' | 'Medium' | 'High';
    temperatureRange?: { min: number; max: number };
  };
  climateCompatibility: string[];
  tips: string[];
  isPublic: boolean;
  requiresPruning?: boolean;
  pruningMonths?: number[];
  produceFruit?: boolean;
  harvestMonths?: number[];
  /** Ajuste estacional de la frecuencia de riego (opcional). */
  seasonalWateringAdjustment?: { summer?: number; winter?: number };
  /** Precipitación mínima en mm para considerar la planta regada por lluvia — opcional. */
  minRainfallMm?: number;
  /** Cantidad de agua en litros por riego — opcional, informativo. */
  waterLitersPerWatering?: number;
}
