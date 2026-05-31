/**
 * @file user_repository_impl.ts
 * @description Implementación concreta del repositorio de usuarios usando MongoDB.
 * Traduce operaciones de dominio a queries MongoDB usando MongoDBConnection.
 * El mapeo entre UserDocument y User se delega al IUserMapper.
 * @module Auth
 * @layer Data
 *
 * @implements {IUserRepository}
 * @injectable
 * @dependencies MongoDBConnection, IUserMapper
 */

import { injectable, inject } from 'inversify';
import { ObjectId, ClientSession } from 'mongodb';
import type { IUserRepository } from '../../domain/repositories/IUserRepository.js';
import type { IUserMapper } from '../IMappers/IUserMapper.js';
import { User } from '../../domain/entities/User.js';
import { MongoDBConnection } from '../datasources/mongodb/MongoDBConnection.js';
import { USER_COLLECTION, UserDocument } from '../datasources/mongodb/models/UserModel.js';
import { TYPES } from '../../core/types.js';
import { NotFoundException } from '../../core/exceptions/NotFoundException.js';
import { createLogger } from '../../core/logger.js';

const logger = createLogger('UserRepository');

/**
 * Repositorio de usuarios con MongoDB.
 * Acepta session opcional en operaciones de escritura para soporte de transacciones.
 *
 * @implements {IUserRepository}
 * @injectable
 * @dependencies MongoDBConnection, IUserMapper
 */
@injectable()
export class UserRepositoryImpl implements IUserRepository {
  constructor(
    @inject(TYPES.MongoDBConnection) private readonly db: MongoDBConnection,
    @inject(TYPES.IUserMapper)       private readonly mapper: IUserMapper,
  ) {}

  /**
   * Obtiene la colección de usuarios de la BD activa.
   * @private
   */
  private get collection() {
    return this.db.getDatabase().collection<UserDocument>(USER_COLLECTION);
  }

  /**
   * Busca un usuario por su id.
   *
   * @param id — ObjectId serializado como string.
   * @returns Usuario encontrado o null.
   */
  async findById(id: string): Promise<User | null> {
    if (!ObjectId.isValid(id)) return null;

    const doc = await this.collection.findOne({
      _id: new ObjectId(id),
      deletedAt: null,
    });

    return doc ? this.mapper.toEntity(doc) : null;
  }

  /**
   * Busca un usuario por email (insensible a mayúsculas).
   *
   * @param email — Email a buscar.
   * @returns Usuario encontrado o null.
   */
  async findByEmail(email: string): Promise<User | null> {
    // Escapar caracteres especiales de regex para emails con puntos, etc.
    const escapedEmail = email.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const doc = await this.collection.findOne({
      email: { $regex: `^${escapedEmail}$`, $options: 'i' },
      deletedAt: null,
    });

    return doc ? this.mapper.toEntity(doc) : null;
  }

  /**
   * Crea un nuevo usuario en la base de datos.
   * Antes de insertar, elimina físicamente cualquier documento soft-deleted con el
   * mismo email para evitar DuplicateKeyError en el índice único.
   *
   * @param user — Datos del usuario sin id.
   * @param session — Sesión de transacción opcional.
   * @returns Usuario creado con id asignado.
   */
  async create(user: Omit<User, 'id'>, session?: ClientSession): Promise<User> {
    const doc = this.mapper.toDocument(user as User);
    const _id = new ObjectId();
    const now = new Date();

    // Purgar registros soft-deleted con el mismo email para liberar el índice único.
    const escapedEmail = doc.email.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    await this.collection.deleteMany(
      { email: { $regex: `^${escapedEmail}$`, $options: 'i' }, deletedAt: { $ne: null } },
      { session },
    );

    const toInsert: UserDocument = {
      ...doc,
      _id,
      createdAt: now,
      updatedAt: now,
    };

    await this.collection.insertOne(toInsert, { session });
    logger.debug(`Usuario creado: ${_id.toHexString()}`);

    return this.mapper.toEntity(toInsert);
  }

  /**
   * Actualiza los campos indicados de un usuario existente.
   *
   * @param id — Id del usuario.
   * @param data — Campos a actualizar.
   * @param session — Sesión de transacción opcional.
   * @returns Usuario actualizado.
   * @throws {NotFoundException} Si el usuario no existe.
   */
  async update(
    id: string,
    data: Partial<Omit<User, 'id' | 'createdAt'>>,
    session?: ClientSession,
  ): Promise<User> {
    if (!ObjectId.isValid(id)) throw new NotFoundException('User', id);

    const result = await this.collection.findOneAndUpdate(
      { _id: new ObjectId(id), deletedAt: null },
      { $set: { ...data, updatedAt: new Date() } },
      { returnDocument: 'after', session },
    );

    if (!result) throw new NotFoundException('User', id);

    logger.debug(`Usuario actualizado: ${id}`);
    return this.mapper.toEntity(result);
  }

  /**
   * Elimina un usuario (lógico por defecto, físico si soft=false).
   *
   * @param id — Id del usuario.
   * @param soft — true → marcar deletedAt. false → eliminar documento.
   * @param session — Sesión de transacción opcional.
   * @throws {NotFoundException} Si el usuario no existe.
   */
  async delete(id: string, soft = true, session?: ClientSession): Promise<void> {
    if (!ObjectId.isValid(id)) throw new NotFoundException('User', id);

    if (soft) {
      const result = await this.collection.updateOne(
        { _id: new ObjectId(id), deletedAt: null },
        { $set: { deletedAt: new Date(), updatedAt: new Date() } },
        { session },
      );
      if (result.matchedCount === 0) throw new NotFoundException('User', id);
    } else {
      const result = await this.collection.deleteOne(
        { _id: new ObjectId(id) },
        { session },
      );
      if (result.deletedCount === 0) throw new NotFoundException('User', id);
    }

    logger.debug(`Usuario ${soft ? 'desactivado (soft)' : 'eliminado (hard)'}: ${id}`);
  }
}
