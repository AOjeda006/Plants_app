/**
 * @file MongoDBConnection.ts
 * @description Gestión del ciclo de vida de la conexión a MongoDB.
 * Provee connect, disconnect, getDatabase, startSession (con fallback sin replica set)
 * y ensureIndexes para crear los índices definidos en database.config.ts.
 * @module Core
 * @layer Data
 */

import { MongoClient, Db, ClientSession } from 'mongodb';
import { injectable } from 'inversify';
import { databaseConfig } from '../../../core/config/database.config.js';
import { createLogger } from '../../../core/logger.js';

const logger = createLogger('MongoDBConnection');

/**
 * Singleton que gestiona la conexión a MongoDB.
 * Se registra en el container DI como TYPES.MongoDBConnection.
 *
 * @injectable
 */
@injectable()
export class MongoDBConnection {
  private client: MongoClient;
  private db: Db | null = null;

  constructor() {
    this.client = new MongoClient(databaseConfig.uri, {
      // Opciones recomendadas para producción
      maxPoolSize: 10,
      serverSelectionTimeoutMS: 5000,
      socketTimeoutMS: 45000,
    });
  }

  /**
   * Establece la conexión con MongoDB y selecciona la base de datos.
   *
   * @throws {Error} Si la conexión falla tras el timeout configurado.
   */
  async connect(): Promise<void> {
    await this.client.connect();
    this.db = this.client.db(databaseConfig.dbName);
    logger.info(`Conectado a MongoDB — base de datos: ${databaseConfig.dbName}`);
  }

  /**
   * Cierra la conexión con MongoDB liberando el pool de conexiones.
   */
  async disconnect(): Promise<void> {
    await this.client.close();
    this.db = null;
    logger.info('Desconectado de MongoDB');
  }

  /**
   * Devuelve la instancia de Db activa.
   *
   * @throws {Error} Si se llama antes de connect().
   * @returns {Db} Instancia de la base de datos MongoDB.
   */
  getDatabase(): Db {
    if (!this.db) {
      throw new Error('MongoDBConnection.getDatabase() llamado antes de connect()');
    }
    return this.db;
  }

  /**
   * Inicia una sesión de cliente MongoDB para transacciones.
   * Si el servidor no soporta replica set (sin transacciones), devuelve undefined
   * y continúa en modo no transaccional.
   *
   * [⚠ TFG]: Sin replica set las transacciones no están disponibles.
   * Los use cases deben ser idempotentes para tolerar este modo.
   *
   * @returns {Promise<ClientSession | undefined>} Sesión activa o undefined si no hay replica set.
   */
  async startSession(): Promise<ClientSession | undefined> {
    try {
      return this.client.startSession();
    } catch {
      logger.warn(
        'startSession fallido — puede que replica set no esté habilitado. ' +
        'Continuando en modo no transaccional.',
      );
      return undefined;
    }
  }

  /**
   * Crea los índices definidos en DEFAULT_INDEXES si no existen ya.
   * Se llama una vez durante el bootstrap de la aplicación.
   */
  async ensureIndexes(): Promise<void> {
    if (!this.db) {
      throw new Error('ensureIndexes() llamado antes de connect()');
    }

    for (const { collection, indexes } of databaseConfig.defaultIndexes) {
      const col = this.db.collection(collection);
      for (const { keys, options } of indexes) {
        try {
          await col.createIndex(keys, options ?? {});
          logger.debug(`Índice creado/verificado en ${collection}: ${JSON.stringify(keys)}`);
        } catch (err) {
          // Un índice que ya existe no es un error crítico
          logger.warn(`No se pudo crear índice en ${collection}: ${(err as Error).message}`);
        }
      }
    }

    logger.info('ensureIndexes completado');
  }
}
