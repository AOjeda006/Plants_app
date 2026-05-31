/**
 * @file IPlantSpeciesMapper.ts
 * @description Interfaz del mapper de especies de plantas. Contrato de conversión PlantSpeciesDocument ↔ PlantSpecies ↔ PlantSpeciesResponseDTO.
 * @module Plants
 * @layer Data
 */

import type { PlantSpecies } from '../../domain/entities/PlantSpecies.js';
import type { PlantSpeciesDocument } from '../datasources/mongodb/models/PlantSpeciesModel.js';
import type { PlantSpeciesResponseDTO } from '../../domain/dtos/plants/plant-species-response.dto.js';

/**
 * Contrato del mapper de especies de plantas.
 */
export interface IPlantSpeciesMapper {
  /**
   * Convierte un documento MongoDB a entidad de dominio.
   *
   * @param doc — Documento de la colección 'plant_species'.
   * @returns Entidad PlantSpecies.
   */
  toEntity(doc: PlantSpeciesDocument): PlantSpecies;

  /**
   * Convierte una entidad de dominio a documento MongoDB (sin _id).
   *
   * @param entity — Entidad PlantSpecies.
   * @returns Documento listo para insertar/actualizar.
   */
  toDocument(entity: PlantSpecies): Omit<PlantSpeciesDocument, '_id'>;

  /**
   * Convierte una entidad de dominio al DTO de respuesta para el cliente.
   *
   * @param entity — Entidad PlantSpecies.
   * @returns DTO serializable para la respuesta HTTP.
   */
  toResponseDTO(entity: PlantSpecies): PlantSpeciesResponseDTO;
}
