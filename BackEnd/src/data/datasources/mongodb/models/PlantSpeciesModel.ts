/**
 * @file PlantSpeciesModel.ts
 * @description Define el nombre de la colección y el tipo del documento MongoDB para PlantSpecies.
 * SIN lógica de mapeo — la transformación entre documento y entidad es responsabilidad
 * exclusiva de los mappers (data/mappers/plant_species_mapper.ts).
 * @module Plants
 * @layer Data
 */

import { ObjectId } from 'mongodb';

/** Nombre de la colección en MongoDB */
export const PLANT_SPECIES_COLLECTION = 'plant_species';

/**
 * Subdocumento de requisitos de cuidado tal como se almacena en MongoDB.
 */
export interface CareRequirementsDocument {
  wateringDays: number;
  lightNeed: 'Low' | 'Medium' | 'High';
  temperatureRange?: { min: number; max: number };
}

/**
 * Subdocumento de auditoría tal como se almacena en MongoDB.
 */
export interface AuditEntryDocument {
  date: Date;
  userId: string;
  changes: string;
}

/**
 * Tipo del documento MongoDB tal como se almacena en la base de datos.
 * NO contiene métodos de negocio ni de mapeo.
 */
export interface PlantSpeciesDocument {
  _id: ObjectId;
  name: string;
  scientificName: string;
  image?: string;
  careRequirements: CareRequirementsDocument;
  climateCompatibility: string[];
  tips: string[];
  createdBy?: ObjectId;
  isPublic: boolean;
  requiresPruning?: boolean;
  pruningMonths?: number[];
  produceFruit?: boolean;
  harvestMonths?: number[];
  /** Ajuste estacional de la frecuencia de riego (opcional). */
  seasonalWateringAdjustment?: { summer?: number; winter?: number };
  /** Precipitación mínima en mm para considerar la planta regada por lluvia (opcional). */
  minRainfallMm?: number;
  /** Cantidad de agua en litros que necesita la planta en cada riego (opcional, informativo). */
  waterLitersPerWatering?: number;
  auditHistory: AuditEntryDocument[];
  createdAt: Date;
  updatedAt: Date;
  deletedAt?: Date | null;
}
