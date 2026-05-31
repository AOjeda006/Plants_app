/**
 * @file PlantModel.ts
 * @description Define el nombre de la colección y el tipo del documento MongoDB para Plant.
 * SIN lógica de mapeo — la transformación entre documento y entidad es responsabilidad
 * exclusiva de los mappers (data/mappers/plant_mapper.ts).
 * @module Plants
 * @layer Data
 */

import { ObjectId } from 'mongodb';

/** Nombre de la colección en MongoDB */
export const PLANT_COLLECTION = 'plants';

/**
 * Subdocumento de override de riego tal como se almacena en MongoDB.
 */
export interface PlantOverrideDocument {
  fromDate: Date;
  toDate: Date;
  wateringFrequencyDays: number;
  reason?: string;
}

/**
 * Subdocumento de reset pendiente por previsión de lluvia.
 */
export interface PendingRainAdjustmentDocument {
  resetAt: Date;
  previousNextWatering: Date | null;
  expectedMm: number;
  locationLat: number;
  locationLon: number;
}

/**
 * Tipo del documento MongoDB tal como se almacena en la base de datos.
 * Los campos usan ObjectId y Date nativos de MongoDB.
 * NO contiene métodos de negocio ni de mapeo.
 */
export interface PlantDocument {
  _id: ObjectId;
  userId: ObjectId;
  name: string;
  speciesId?: ObjectId;
  photo?: string;
  location: 'Interior' | 'Exterior';
  plantLocation?: string;
  plantLocationLat?: number;
  plantLocationLon?: number;
  wateringFrequency: number;
  lightNeed: 'Low' | 'Medium' | 'High';
  pruningFrequency?: number;
  notes?: string;
  nextWatering?: Date;
  nextPruning?: Date;
  considerWeatherForWatering: boolean;
  overrides?: PlantOverrideDocument[];
  pendingRainAdjustment?: PendingRainAdjustmentDocument;
  createdAt: Date;
  updatedAt: Date;
  deletedAt?: Date | null;
}
