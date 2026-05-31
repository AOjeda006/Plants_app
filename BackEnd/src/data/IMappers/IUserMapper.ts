/**
 * @file IUserMapper.ts
 * @description Interfaz del mapper de usuarios.
 * Define el contrato de transformación entre UserDocument (MongoDB) y User (entidad de dominio).
 * @module Auth
 * @layer Data
 */

import { User } from '../../domain/entities/User.js';
import { UserDocument } from '../datasources/mongodb/models/UserModel.js';

/**
 * Contrato del mapper de usuarios.
 * La implementación concreta vive en data/mappers/user_mapper.ts.
 */
export interface IUserMapper {
  /**
   * Convierte un documento MongoDB en una entidad de dominio User.
   *
   * @param doc — Documento tal como se almacena en MongoDB.
   * @returns Entidad User del dominio.
   */
  toEntity(doc: UserDocument): User;

  /**
   * Convierte una entidad User en un documento listo para insertar/actualizar en MongoDB.
   *
   * @param user — Entidad de dominio.
   * @returns Documento MongoDB (sin _id si es inserción nueva).
   */
  toDocument(user: User): Omit<UserDocument, '_id'>;
}
