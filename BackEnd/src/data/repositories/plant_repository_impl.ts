/**
 * @file plant_repository_impl.ts
 * @description Implementación concreta del repositorio de plantas usando MongoDB.
 * Delega el mapeo entre PlantDocument y Plant al IPlantMapper.
 * @module Plants
 * @layer Data
 *
 * @implements {IPlantRepository}
 * @injectable
 * @dependencies MongoDBConnection, IPlantMapper
 */

import { injectable, inject } from 'inversify';
import { ObjectId, ClientSession } from 'mongodb';
import type { IPlantRepository } from '../../domain/repositories/IPlantRepository.js';
import type { IPlantMapper } from '../IMappers/IPlantMapper.js';
import { Plant } from '../../domain/entities/Plant.js';
import { MongoDBConnection } from '../datasources/mongodb/MongoDBConnection.js';
import { PLANT_COLLECTION, PlantDocument } from '../datasources/mongodb/models/PlantModel.js';
import { TYPES } from '../../core/types.js';
import { NotFoundException } from '../../core/exceptions/NotFoundException.js';
import { createLogger } from '../../core/logger.js';

const logger = createLogger('PlantRepository');

/**
 * Repositorio de plantas con MongoDB.
 *
 * @implements {IPlantRepository}
 * @injectable
 * @dependencies MongoDBConnection, IPlantMapper
 */
@injectable()
export class PlantRepositoryImpl implements IPlantRepository {
  constructor(
    @inject(TYPES.MongoDBConnection) private readonly db: MongoDBConnection,
    @inject(TYPES.IPlantMapper)       private readonly mapper: IPlantMapper,
  ) {}

  /**
   * Obtiene la colección de plantas de la BD activa.
   * @private
   */
  private get collection() {
    return this.db.getDatabase().collection<PlantDocument>(PLANT_COLLECTION);
  }

  /**
   * Obtiene todas las plantas activas de un usuario, ordenadas por nombre.
   *
   * @param userId — Id del usuario propietario.
   * @returns Lista de plantas del usuario.
   */
  async findByUserId(userId: string): Promise<Plant[]> {
    if (!ObjectId.isValid(userId)) return [];

    const docs = await this.collection
      .find({ userId: new ObjectId(userId), deletedAt: null })
      .sort({ name: 1 })
      .toArray();

    return docs.map((d) => this.mapper.toEntity(d));
  }

  /**
   * Busca una planta por su id. Incluye plantas borradas lógicamente.
   *
   * @param id — Id de la planta.
   * @returns Planta encontrada o null.
   */
  async findById(id: string): Promise<Plant | null> {
    if (!ObjectId.isValid(id)) return null;

    const doc = await this.collection.findOne({ _id: new ObjectId(id) });
    return doc ? this.mapper.toEntity(doc) : null;
  }

  /**
   * Crea una nueva planta en la base de datos.
   *
   * @param plant — Datos de la planta sin id.
   * @param session — Sesión de transacción opcional.
   * @returns Planta creada con id asignado.
   */
  async create(plant: Omit<Plant, 'id'>, session?: ClientSession): Promise<Plant> {
    const doc = this.mapper.toDocument(plant as Plant);
    const _id = new ObjectId();
    const now = new Date();

    const toInsert: PlantDocument = {
      ...doc,
      _id,
      createdAt: now,
      updatedAt: now,
    };

    await this.collection.insertOne(toInsert, { session });
    logger.debug(`Planta creada: ${_id.toHexString()}`);

    return this.mapper.toEntity(toInsert);
  }

  /**
   * Actualiza los campos indicados de una planta existente.
   *
   * @param id — Id de la planta.
   * @param data — Campos parciales a actualizar.
   * @param session — Sesión de transacción opcional.
   * @returns Planta actualizada.
   * @throws {NotFoundException} Si la planta no existe o está borrada.
   */
  async update(
    id: string,
    data: Partial<Omit<Plant, 'id' | 'createdAt'>>,
    session?: ClientSession,
  ): Promise<Plant> {
    if (!ObjectId.isValid(id)) throw new NotFoundException('Plant', id);

    // Convertir campos con string IDs a ObjectId para MongoDB.
    // userId no es actualizable; speciesId puede ser string en la entidad.
    const { speciesId, userId: _userId, ...rest } = data;
    const docUpdate: Record<string, unknown> = { ...(rest as Record<string, unknown>) };
    if (speciesId !== undefined) {
      docUpdate['speciesId'] = speciesId && ObjectId.isValid(speciesId) ? new ObjectId(speciesId) : null;
    }

    const result = await this.collection.findOneAndUpdate(
      { _id: new ObjectId(id), deletedAt: null },
      { $set: { ...docUpdate, updatedAt: new Date() } },
      { returnDocument: 'after', session },
    );

    if (!result) throw new NotFoundException('Plant', id);

    logger.debug(`Planta actualizada: ${id}`);
    return this.mapper.toEntity(result);
  }

  /**
   * Elimina una planta (soft delete por defecto).
   *
   * @param id — Id de la planta.
   * @param soft — true → marcar deletedAt. false → eliminar físicamente.
   * @param session — Sesión de transacción opcional.
   * @throws {NotFoundException} Si la planta no existe.
   */
  async delete(id: string, soft = true, session?: ClientSession): Promise<void> {
    if (!ObjectId.isValid(id)) throw new NotFoundException('Plant', id);

    if (soft) {
      const result = await this.collection.updateOne(
        { _id: new ObjectId(id), deletedAt: null },
        { $set: { deletedAt: new Date(), updatedAt: new Date() } },
        { session },
      );
      if (result.matchedCount === 0) throw new NotFoundException('Plant', id);
    } else {
      const result = await this.collection.deleteOne(
        { _id: new ObjectId(id) },
        { session },
      );
      if (result.deletedCount === 0) throw new NotFoundException('Plant', id);
    }

    logger.debug(`Planta ${soft ? 'desactivada (soft)' : 'eliminada (hard)'}: ${id}`);
  }

  /**
   * Busca todas las plantas activas que tienen asignada una especie concreta.
   * Usado por el cron job de cosecha.
   *
   * @param speciesId — Id de la especie.
   * @returns Lista de plantas no eliminadas con esa especie.
   */
  async findBySpeciesId(speciesId: string): Promise<Plant[]> {
    if (!ObjectId.isValid(speciesId)) return [];

    const docs = await this.collection
      .find({
        speciesId: new ObjectId(speciesId),
        deletedAt: null,
      })
      .toArray();

    return docs.map((d) => this.mapper.toEntity(d));
  }

  /**
   * Busca plantas cuyo nextWatering cae dentro de las próximas windowHours horas.
   * Usado por el cron job de recordatorios.
   *
   * @param windowHours — Ventana de tiempo en horas (por defecto 24).
   * @returns Lista de plantas que necesitan atención.
   */
  async findPlantsNeedingCare(windowHours = 24): Promise<Plant[]> {
    const now = new Date();
    const windowEnd = new Date(now.getTime() + windowHours * 60 * 60 * 1000);

    const docs = await this.collection
      .find({
        deletedAt: null,
        nextWatering: { $lte: windowEnd },
      })
      .toArray();

    return docs.map((d) => this.mapper.toEntity(d));
  }

  /**
   * Devuelve los userIds únicos de usuarios que tienen al menos una planta activa.
   *
   * @returns Lista de userIds como strings hexadecimales.
   */
  async findDistinctUserIds(): Promise<string[]> {
    const userIds = await this.collection.distinct('userId', { deletedAt: null });
    return userIds.map((id) => id.toHexString());
  }
}
