/**
 * @file weather_cache_repository_impl.ts
 * @description Implementación concreta del repositorio de caché meteorológica usando MongoDB.
 * Usa upsert por locationKey para garantizar una sola entrada por localización.
 * @module Weather
 * @layer Data
 *
 * @implements {IWeatherCacheRepository}
 * @injectable
 * @dependencies MongoDBConnection, IWeatherMapper
 */

import { injectable, inject } from 'inversify';
import { ObjectId, ClientSession } from 'mongodb';
import type { IWeatherCacheRepository } from '../../domain/repositories/IWeatherCacheRepository.js';
import type { IWeatherMapper } from '../IMappers/IWeatherMapper.js';
import { WeatherCache } from '../../domain/entities/WeatherCache.js';
import { MongoDBConnection } from '../datasources/mongodb/MongoDBConnection.js';
import { WEATHER_CACHE_COLLECTION, WeatherCacheDocument } from '../datasources/mongodb/models/WeatherCacheModel.js';
import { TYPES } from '../../core/types.js';
import { createLogger } from '../../core/logger.js';

const logger = createLogger('WeatherCacheRepository');

/**
 * Repositorio de caché meteorológica con MongoDB.
 *
 * @implements {IWeatherCacheRepository}
 * @injectable
 * @dependencies MongoDBConnection, IWeatherMapper
 */
@injectable()
export class WeatherCacheRepositoryImpl implements IWeatherCacheRepository {
  constructor(
    @inject(TYPES.MongoDBConnection)  private readonly db: MongoDBConnection,
    @inject(TYPES.IWeatherCacheMapper) private readonly mapper: IWeatherMapper,
  ) {}

  /**
   * Obtiene la colección de caché meteorológica.
   * @private
   */
  private get collection() {
    return this.db.getDatabase().collection<WeatherCacheDocument>(WEATHER_CACHE_COLLECTION);
  }

  /**
   * Busca la entrada de caché vigente para una clave de localización.
   * Devuelve null si ha expirado o no existe.
   *
   * @param locationKey — Clave normalizada lat,lon.
   * @returns WeatherCache vigente o null.
   */
  async findByLocationKey(locationKey: string): Promise<WeatherCache | null> {
    const doc = await this.collection.findOne({ locationKey });
    if (!doc) return null;

    const entity = this.mapper.toEntity(doc);
    // Devolver null si ha expirado para que el servicio refresque los datos
    return entity.isExpired() ? null : entity;
  }

  /**
   * Guarda o actualiza la caché para una localización (upsert por locationKey).
   *
   * @param cache — Datos de caché sin id.
   * @param session — Sesión de transacción opcional.
   * @returns WeatherCache persistida.
   */
  async save(
    cache: Omit<WeatherCache, 'id' | 'isExpired'>,
    session?: ClientSession,
  ): Promise<WeatherCache> {
    const now = new Date();

    const result = await this.collection.findOneAndUpdate(
      { locationKey: cache.locationKey },
      {
        $set: {
          data:      cache.data,
          fetchedAt: cache.fetchedAt,
          expiresAt: cache.expiresAt,
        },
        $setOnInsert: {
          _id:         new ObjectId(),
          locationKey: cache.locationKey,
        },
      },
      { upsert: true, returnDocument: 'after', session },
    );

    if (!result) {
      // fallback: leer el documento recién insertado
      const doc = await this.collection.findOne({ locationKey: cache.locationKey });
      if (!doc) throw new Error(`WeatherCache save failed for locationKey: ${cache.locationKey}`);
      logger.debug(`WeatherCache guardado (fallback): ${cache.locationKey}`);
      return this.mapper.toEntity(doc);
    }

    logger.debug(`WeatherCache guardado: ${cache.locationKey} | expira: ${cache.expiresAt.toISOString()}`);
    return this.mapper.toEntity(result);
  }

  /**
   * Elimina entradas de caché expiradas.
   * Invocado por CleanupExpiredWeatherCacheJob.
   *
   * @returns Número de documentos eliminados.
   */
  async deleteExpired(): Promise<number> {
    const result = await this.collection.deleteMany({
      expiresAt: { $lt: new Date() },
    });

    logger.info(`WeatherCache limpieza: ${result.deletedCount} entradas expiradas eliminadas`);
    return result.deletedCount;
  }
}
