/**
 * @file plant_species_mapper.ts
 * @description Implementación del mapper de especies de plantas.
 * Convierte entre PlantSpeciesDocument (MongoDB), PlantSpecies (dominio) y PlantSpeciesResponseDTO.
 * @module Plants
 * @layer Data
 *
 * @implements {IPlantSpeciesMapper}
 * @injectable
 */

import { injectable } from 'inversify';
import { ObjectId } from 'mongodb';
import type { IPlantSpeciesMapper } from '../IMappers/IPlantSpeciesMapper.js';
import { PlantSpecies, CareRequirements, AuditEntry } from '../../domain/entities/PlantSpecies.js';
import type { LightNeed } from '../../domain/entities/Plant.js';
import { PlantSpeciesDocument, CareRequirementsDocument, AuditEntryDocument } from '../datasources/mongodb/models/PlantSpeciesModel.js';
import type { PlantSpeciesResponseDTO } from '../../domain/dtos/plants/plant-species-response.dto.js';

/**
 * Mapper de especies de plantas.
 *
 * @implements {IPlantSpeciesMapper}
 * @injectable
 */
@injectable()
export class PlantSpeciesMapper implements IPlantSpeciesMapper {

  /**
   * Convierte un documento MongoDB a entidad PlantSpecies.
   *
   * @param doc — Documento de la colección 'plant_species'.
   * @returns Entidad PlantSpecies.
   */
  toEntity(doc: PlantSpeciesDocument): PlantSpecies {
    return new PlantSpecies({
      id:                   doc._id.toHexString(),
      name:                 doc.name,
      scientificName:       doc.scientificName,
      image:                doc.image,
      careRequirements:     this._toCareRequirements(doc.careRequirements),
      climateCompatibility: doc.climateCompatibility,
      tips:                 doc.tips,
      createdBy:            doc.createdBy?.toHexString(),
      isPublic:             doc.isPublic,
      requiresPruning:      doc.requiresPruning,
      pruningMonths:         doc.pruningMonths,
      produceFruit:                 doc.produceFruit,
      harvestMonths:                doc.harvestMonths,
      seasonalWateringAdjustment:   doc.seasonalWateringAdjustment,
      minRainfallMm:                doc.minRainfallMm,
      waterLitersPerWatering:       doc.waterLitersPerWatering,
      auditHistory:                 doc.auditHistory.map(this._toAuditEntry),
      createdAt:            doc.createdAt,
      updatedAt:            doc.updatedAt,
      deletedAt:            doc.deletedAt,
    });
  }

  /**
   * Convierte una entidad PlantSpecies a documento MongoDB (sin _id).
   *
   * @param entity — Entidad PlantSpecies.
   * @returns Documento parcial para insertar/actualizar.
   */
  toDocument(entity: PlantSpecies): Omit<PlantSpeciesDocument, '_id'> {
    return {
      name:                 entity.name,
      scientificName:       entity.scientificName,
      image:                entity.image,
      careRequirements:     this._toCareRequirementsDoc(entity.careRequirements),
      climateCompatibility: entity.climateCompatibility,
      tips:                 entity.tips,
      createdBy:            entity.createdBy ? new ObjectId(entity.createdBy) : undefined,
      isPublic:             entity.isPublic,
      requiresPruning:      entity.requiresPruning,
      pruningMonths:         entity.pruningMonths,
      produceFruit:                 entity.produceFruit,
      harvestMonths:                entity.harvestMonths,
      seasonalWateringAdjustment:   entity.seasonalWateringAdjustment,
      minRainfallMm:                entity.minRainfallMm,
      waterLitersPerWatering:       entity.waterLitersPerWatering,
      auditHistory:                 entity.auditHistory.map(this._toAuditEntryDoc),
      createdAt:            entity.createdAt,
      updatedAt:            entity.updatedAt,
      deletedAt:            entity.deletedAt,
    };
  }

  /**
   * Convierte una entidad PlantSpecies al DTO de respuesta HTTP.
   *
   * @param entity — Entidad PlantSpecies.
   * @returns PlantSpeciesResponseDTO serializable.
   */
  toResponseDTO(entity: PlantSpecies): PlantSpeciesResponseDTO {
    return {
      id:                   entity.id,
      name:                 entity.name,
      scientificName:       entity.scientificName,
      image:                entity.image,
      careRequirements: {
        wateringDays:     entity.careRequirements.wateringDays,
        lightNeed:        entity.careRequirements.lightNeed,
        temperatureRange: entity.careRequirements.temperatureRange,
      },
      climateCompatibility: entity.climateCompatibility,
      tips:                 entity.tips,
      isPublic:             entity.isPublic,
      requiresPruning:              entity.requiresPruning,
      pruningMonths:                 entity.pruningMonths,
      produceFruit:                 entity.produceFruit,
      harvestMonths:                entity.harvestMonths,
      seasonalWateringAdjustment:   entity.seasonalWateringAdjustment,
      minRainfallMm:                entity.minRainfallMm,
      waterLitersPerWatering:       entity.waterLitersPerWatering,
    };
  }

  /**
   * Convierte subdocumento de cuidados a tipo de dominio.
   * @private
   */
  private _toCareRequirements(doc: CareRequirementsDocument): CareRequirements {
    return {
      wateringDays:     doc.wateringDays,
      lightNeed:        doc.lightNeed as LightNeed,
      temperatureRange: doc.temperatureRange,
    };
  }

  /**
   * Convierte cuidados de dominio a subdocumento MongoDB.
   * @private
   */
  private _toCareRequirementsDoc(req: CareRequirements): CareRequirementsDocument {
    return {
      wateringDays:     req.wateringDays,
      lightNeed:        req.lightNeed,
      temperatureRange: req.temperatureRange,
    };
  }

  /**
   * Convierte subdocumento de auditoría a tipo de dominio.
   * @private
   */
  private _toAuditEntry(doc: AuditEntryDocument): AuditEntry {
    return {
      date:    doc.date,
      userId:  doc.userId,
      changes: doc.changes,
    };
  }

  /**
   * Convierte entrada de auditoría de dominio a subdocumento MongoDB.
   * @private
   */
  private _toAuditEntryDoc(entry: AuditEntry): AuditEntryDocument {
    return {
      date:    entry.date,
      userId:  entry.userId,
      changes: entry.changes,
    };
  }
}
