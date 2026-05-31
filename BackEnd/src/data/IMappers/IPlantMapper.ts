/**
 * @file IPlantMapper.ts
 * @description Interfaz del mapper de plantas. Contrato de conversión PlantDocument ↔ Plant ↔ PlantResponseDTO.
 * @module Plants
 * @layer Data
 */

import type { Plant } from '../../domain/entities/Plant.js';
import type { PlantDocument } from '../datasources/mongodb/models/PlantModel.js';
import type { PlantResponseDTO } from '../../domain/dtos/plants/plant-response.dto.js';

/**
 * Contrato del mapper de plantas.
 */
export interface IPlantMapper {
  /**
   * Convierte un documento MongoDB a entidad de dominio.
   *
   * @param doc — Documento de la colección 'plants'.
   * @returns Entidad Plant.
   */
  toEntity(doc: PlantDocument): Plant;

  /**
   * Convierte una entidad de dominio a documento MongoDB (sin _id).
   *
   * @param entity — Entidad Plant.
   * @returns Documento listo para insertar/actualizar.
   */
  toDocument(entity: Plant): Omit<PlantDocument, '_id'>;

  /**
   * Convierte una entidad de dominio al DTO de respuesta para el cliente.
   *
   * @param entity — Entidad Plant.
   * @returns DTO serializable para la respuesta HTTP.
   */
  toResponseDTO(entity: Plant): PlantResponseDTO;
}
