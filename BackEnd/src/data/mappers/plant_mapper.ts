/**
 * @file plant_mapper.ts
 * @description Implementación del mapper de plantas.
 * Convierte entre PlantDocument (MongoDB), Plant (dominio) y PlantResponseDTO (presentación).
 * @module Plants
 * @layer Data
 *
 * @implements {IPlantMapper}
 * @injectable
 */

import { injectable } from 'inversify';
import { ObjectId } from 'mongodb';
import type { IPlantMapper } from '../IMappers/IPlantMapper.js';
import { Plant, PlantOverride, LightNeed, PlantLocation } from '../../domain/entities/Plant.js';
import { PlantDocument, PlantOverrideDocument } from '../datasources/mongodb/models/PlantModel.js';
import type { PlantResponseDTO } from '../../domain/dtos/plants/plant-response.dto.js';

/**
 * Mapper de plantas.
 *
 * @implements {IPlantMapper}
 * @injectable
 */
@injectable()
export class PlantMapper implements IPlantMapper {

  /**
   * Convierte un documento MongoDB a entidad Plant.
   *
   * @param doc — Documento de la colección 'plants'.
   * @returns Entidad Plant.
   */
  toEntity(doc: PlantDocument): Plant {
    return new Plant({
      id:                        doc._id.toHexString(),
      userId:                    doc.userId.toHexString(),
      name:                      doc.name,
      speciesId:                 doc.speciesId?.toHexString(),
      photo:                     doc.photo,
      location:                  doc.location as PlantLocation,
      plantLocation:             doc.plantLocation,
      plantLocationLat:          doc.plantLocationLat,
      plantLocationLon:          doc.plantLocationLon,
      wateringFrequency:         doc.wateringFrequency,
      lightNeed:                 doc.lightNeed as LightNeed,
      pruningFrequency:          doc.pruningFrequency,
      notes:                     doc.notes,
      nextWatering:              doc.nextWatering,
      nextPruning:               doc.nextPruning,
      considerWeatherForWatering: doc.considerWeatherForWatering,
      overrides:                 doc.overrides?.map(this._toOverride),
      pendingRainAdjustment:     doc.pendingRainAdjustment
        ? {
            resetAt:              doc.pendingRainAdjustment.resetAt,
            previousNextWatering: doc.pendingRainAdjustment.previousNextWatering,
            expectedMm:           doc.pendingRainAdjustment.expectedMm,
            locationLat:          doc.pendingRainAdjustment.locationLat,
            locationLon:          doc.pendingRainAdjustment.locationLon,
          }
        : undefined,
      createdAt:                 doc.createdAt,
      updatedAt:                 doc.updatedAt,
      deletedAt:                 doc.deletedAt,
    });
  }

  /**
   * Convierte una entidad Plant a documento MongoDB (sin _id, createdAt, updatedAt).
   *
   * @param entity — Entidad Plant.
   * @returns Documento parcial para insertar/actualizar.
   */
  toDocument(entity: Plant): Omit<PlantDocument, '_id'> {
    return {
      userId:                    new ObjectId(entity.userId),
      name:                      entity.name,
      speciesId:                 entity.speciesId ? new ObjectId(entity.speciesId) : undefined,
      photo:                     entity.photo,
      location:                  entity.location,
      plantLocation:             entity.plantLocation,
      plantLocationLat:          entity.plantLocationLat,
      plantLocationLon:          entity.plantLocationLon,
      wateringFrequency:         entity.wateringFrequency,
      lightNeed:                 entity.lightNeed,
      pruningFrequency:          entity.pruningFrequency,
      notes:                     entity.notes,
      nextWatering:              entity.nextWatering,
      nextPruning:               entity.nextPruning,
      considerWeatherForWatering: entity.considerWeatherForWatering,
      overrides:                 entity.overrides?.map(this._toOverrideDoc),
      pendingRainAdjustment:     entity.pendingRainAdjustment
        ? {
            resetAt:              entity.pendingRainAdjustment.resetAt,
            previousNextWatering: entity.pendingRainAdjustment.previousNextWatering,
            expectedMm:           entity.pendingRainAdjustment.expectedMm,
            locationLat:          entity.pendingRainAdjustment.locationLat,
            locationLon:          entity.pendingRainAdjustment.locationLon,
          }
        : undefined,
      createdAt:                 entity.createdAt,
      updatedAt:                 entity.updatedAt,
      deletedAt:                 entity.deletedAt,
    };
  }

  /**
   * Convierte una entidad Plant al DTO de respuesta HTTP.
   *
   * @param entity — Entidad Plant.
   * @returns PlantResponseDTO serializable.
   */
  toResponseDTO(entity: Plant): PlantResponseDTO {
    return {
      id:                        entity.id,
      userId:                    entity.userId,
      name:                      entity.name,
      speciesId:                 entity.speciesId,
      photo:                     entity.photo,
      location:                  entity.location,
      plantLocation:             entity.plantLocation,
      plantLocationLat:          entity.plantLocationLat,
      plantLocationLon:          entity.plantLocationLon,
      wateringFrequency:         entity.wateringFrequency,
      lightNeed:                 entity.lightNeed,
      pruningFrequency:          entity.pruningFrequency,
      notes:                     entity.notes,
      nextWatering:              entity.nextWatering?.toISOString(),
      nextPruning:               entity.nextPruning?.toISOString(),
      considerWeatherForWatering: entity.considerWeatherForWatering,
      createdAt:                 entity.createdAt.toISOString(),
      updatedAt:                 entity.updatedAt.toISOString(),
    };
  }

  /**
   * Convierte un subdocumento de override a tipo de dominio.
   * @private
   */
  private _toOverride(doc: PlantOverrideDocument): PlantOverride {
    return {
      fromDate:              doc.fromDate,
      toDate:                doc.toDate,
      wateringFrequencyDays: doc.wateringFrequencyDays,
      reason:                doc.reason,
    };
  }

  /**
   * Convierte un override de dominio a subdocumento MongoDB.
   * @private
   */
  private _toOverrideDoc(override: PlantOverride): PlantOverrideDocument {
    return {
      fromDate:              override.fromDate,
      toDate:                override.toDate,
      wateringFrequencyDays: override.wateringFrequencyDays,
      reason:                override.reason,
    };
  }
}
