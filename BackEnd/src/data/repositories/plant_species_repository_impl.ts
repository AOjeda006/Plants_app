/**
 * @file plant_species_repository_impl.ts
 * @description Implementación concreta del repositorio de especies de plantas usando MongoDB.
 * Delega el mapeo entre PlantSpeciesDocument y PlantSpecies al IPlantSpeciesMapper.
 * @module Plants
 * @layer Data
 *
 * @implements {IPlantSpeciesRepository}
 * @injectable
 * @dependencies MongoDBConnection, IPlantSpeciesMapper
 */

import { injectable, inject } from 'inversify';
import { ObjectId, ClientSession } from 'mongodb';
import type { IPlantSpeciesRepository } from '../../domain/repositories/IPlantSpeciesRepository.js';
import type { IPlantSpeciesMapper } from '../IMappers/IPlantSpeciesMapper.js';
import { PlantSpecies } from '../../domain/entities/PlantSpecies.js';
import { MongoDBConnection } from '../datasources/mongodb/MongoDBConnection.js';
import { PLANT_SPECIES_COLLECTION, PlantSpeciesDocument } from '../datasources/mongodb/models/PlantSpeciesModel.js';
import { TYPES } from '../../core/types.js';
import { NotFoundException } from '../../core/exceptions/NotFoundException.js';
import { createLogger } from '../../core/logger.js';

const logger = createLogger('PlantSpeciesRepository');

/**
 * Repositorio de especies de plantas con MongoDB.
 *
 * @implements {IPlantSpeciesRepository}
 * @injectable
 * @dependencies MongoDBConnection, IPlantSpeciesMapper
 */
@injectable()
export class PlantSpeciesRepositoryImpl implements IPlantSpeciesRepository {
  constructor(
    @inject(TYPES.MongoDBConnection)    private readonly db: MongoDBConnection,
    @inject(TYPES.IPlantSpeciesMapper)  private readonly mapper: IPlantSpeciesMapper,
  ) {}

  /**
   * Obtiene la colección de especies de la BD activa.
   * @private
   */
  private get collection() {
    return this.db.getDatabase().collection<PlantSpeciesDocument>(PLANT_SPECIES_COLLECTION);
  }

  /**
   * Busca una especie por su id.
   *
   * @param id — Id de la especie.
   * @returns Especie encontrada o null.
   */
  async findById(id: string): Promise<PlantSpecies | null> {
    if (!ObjectId.isValid(id)) return null;

    const doc = await this.collection.findOne({
      _id: new ObjectId(id),
      deletedAt: null,
    });

    return doc ? this.mapper.toEntity(doc) : null;
  }

  /**
   * Busca especies públicas por texto libre (nombre o nombre científico).
   * Usa índice de texto o regex según disponibilidad.
   *
   * @param query — Texto de búsqueda.
   * @returns Lista de especies coincidentes ordenadas por nombre.
   */
  async search(query: string): Promise<PlantSpecies[]> {
    // Filtro base: solo especies públicas no eliminadas.
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const filter: Record<string, any> = {
      isPublic: true,
      deletedAt: null,
    };

    // Con query: añadir regex case-insensitive en nombre y nombre científico.
    // Sin query: devolver todas las especies públicas (para autocompletado inicial).
    if (query) {
      const escaped = query.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      filter['$or'] = [
        { name:           { $regex: escaped, $options: 'i' } },
        { scientificName: { $regex: escaped, $options: 'i' } },
      ];
    }

    const docs = await this.collection
      .find(filter)
      .sort({ name: 1 })
      .limit(50)
      .toArray();

    return docs.map((d) => this.mapper.toEntity(d));
  }

  /**
   * Devuelve todas las especies públicas con produceFruit=true que tienen el mes
   * indicado en su array harvestMonths. Usado por el cron job de cosecha.
   *
   * @param month — Mes del año (1 = enero, 12 = diciembre).
   * @returns Lista de especies frutales activas.
   */
  async findFruitingThisMonth(month: number): Promise<PlantSpecies[]> {
    const docs = await this.collection
      .find({
        isPublic:     true,
        deletedAt:    null,
        produceFruit: true,
        harvestMonths: month,
      })
      .toArray();

    return docs.map((d) => this.mapper.toEntity(d));
  }

  /**
   * Devuelve todas las especies públicas que requieren poda en el mes indicado.
   * Usado por el cron job de poda.
   *
   * @param month — Mes del año (1 = enero, 12 = diciembre).
   * @returns Lista de especies con requiresPruning=true y pruningMonths que incluya el mes indicado.
   */
  async findPruningThisMonth(month: number): Promise<PlantSpecies[]> {
    const docs = await this.collection
      .find({
        isPublic:       true,
        deletedAt:      null,
        requiresPruning: true,
        pruningMonths:  month,
      })
      .toArray();

    return docs.map((d) => this.mapper.toEntity(d));
  }

  /**
   * Elimina una especie (soft delete por defecto).
   *
   * @param id — Id de la especie.
   * @param soft — true → marcar deletedAt. false → eliminar físicamente.
   * @param session — Sesión de transacción opcional.
   */
  async delete(id: string, soft = true, session?: ClientSession): Promise<void> {
    if (!ObjectId.isValid(id)) throw new NotFoundException('PlantSpecies', id);

    if (soft) {
      const result = await this.collection.updateOne(
        { _id: new ObjectId(id), deletedAt: null },
        { $set: { deletedAt: new Date(), updatedAt: new Date() } },
        { session },
      );
      if (result.matchedCount === 0) throw new NotFoundException('PlantSpecies', id);
    } else {
      const result = await this.collection.deleteOne(
        { _id: new ObjectId(id) },
        { session },
      );
      if (result.deletedCount === 0) throw new NotFoundException('PlantSpecies', id);
    }

    logger.debug(`Especie ${soft ? 'desactivada (soft)' : 'eliminada (hard)'}: ${id}`);
  }
}
