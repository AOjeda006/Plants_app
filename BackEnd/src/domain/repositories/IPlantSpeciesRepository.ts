/**
 * @file IPlantSpeciesRepository.ts
 * @description Interfaz del repositorio de especies de plantas.
 * @module Plants
 * @layer Domain
 */

import type { ClientSession } from 'mongodb';
import type { PlantSpecies } from '../entities/PlantSpecies.js';

/**
 * Contrato del repositorio de especies.
 */
export interface IPlantSpeciesRepository {
  /**
   * Busca una especie por su id.
   *
   * @param id — Id de la especie.
   * @returns Especie encontrada o null.
   */
  findById(id: string): Promise<PlantSpecies | null>;

  /**
   * Busca especies por nombre o nombre científico (texto libre).
   * Solo devuelve especies públicas (isPublic=true).
   *
   * @param query — Texto de búsqueda.
   * @returns Lista de especies coincidentes.
   */
  search(query: string): Promise<PlantSpecies[]>;

  /**
   * Devuelve todas las especies públicas que producen fruto en el mes indicado.
   * Usado por el cron job de cosecha.
   *
   * @param month — Mes del año (1 = enero, 12 = diciembre).
   * @returns Lista de especies frutales activas con ese mes en harvestMonths.
   */
  findFruitingThisMonth(month: number): Promise<PlantSpecies[]>;

  /**
   * Devuelve todas las especies públicas que requieren poda en el mes indicado.
   * Usado por el cron job de poda.
   *
   * @param month — Mes del año (1 = enero, 12 = diciembre).
   * @returns Lista de especies con requiresPruning=true y pruningMonths que incluya el mes indicado.
   */
  findPruningThisMonth(month: number): Promise<PlantSpecies[]>;

  /**
   * Elimina una especie (soft delete por defecto).
   *
   * @param id — Id de la especie.
   * @param soft — true → marcar deletedAt. false → eliminar físicamente.
   * @param session — Sesión de transacción opcional.
   */
  delete(id: string, soft?: boolean, session?: ClientSession): Promise<void>;
}
