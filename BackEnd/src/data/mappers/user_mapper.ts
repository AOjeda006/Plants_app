/**
 * @file user_mapper.ts
 * @description Implementación del mapper de usuarios.
 * Transforma entre UserDocument (capa data) y User (entidad de dominio).
 * Es la única clase que conoce ambas representaciones.
 * @module Auth
 * @layer Data
 *
 * @implements {IUserMapper}
 * @injectable
 */

import { injectable } from 'inversify';
import { ObjectId } from 'mongodb';
import { IUserMapper } from '../IMappers/IUserMapper.js';
import { User } from '../../domain/entities/User.js';
import { UserDocument } from '../datasources/mongodb/models/UserModel.js';

/**
 * Mapper concreto de usuarios entre capa data y dominio.
 *
 * @implements {IUserMapper}
 * @injectable
 */
@injectable()
export class UserMapper implements IUserMapper {
  /**
   * Convierte un UserDocument de MongoDB en una entidad User de dominio.
   *
   * @param doc — Documento MongoDB con ObjectId y Dates nativos.
   * @returns Entidad User del dominio.
   */
  toEntity(doc: UserDocument): User {
    return new User({
      id:           doc._id.toHexString(),
      role:         doc.role ?? 'user',
      name:         doc.name,
      email:        doc.email,
      passwordHash: doc.passwordHash,
      // Normalizar null a undefined en campos opcionales para mantener la entidad limpia
      photo:        doc.photo       ?? undefined,
      bannerPhoto:  doc.bannerPhoto ?? undefined,
      bio:          doc.bio         ?? undefined,
      location:     doc.location    ?? undefined,
      locationLat:  doc.locationLat ?? undefined,
      locationLon:  doc.locationLon ?? undefined,
      fcmToken:     doc.fcmToken    ?? undefined,
      lastChatPushTitle: doc.lastChatPushTitle ?? null,
      preferences:  doc.preferences,
      createdAt:    doc.createdAt,
      updatedAt:    doc.updatedAt,
      deletedAt:    doc.deletedAt  ?? undefined,
      bannedUntil:  doc.bannedUntil ?? undefined,
    });
  }

  /**
   * Convierte una entidad User de dominio en un documento para MongoDB.
   * No incluye _id (lo asigna el repositorio al insertar).
   *
   * @param user — Entidad de dominio.
   * @returns Documento MongoDB sin _id.
   */
  toDocument(user: User): Omit<UserDocument, '_id'> {
    return {
      role:         user.role,
      name:         user.name,
      email:        user.email,
      passwordHash: user.passwordHash,
      photo:        user.photo,
      bannerPhoto:  user.bannerPhoto,
      bio:          user.bio,
      location:     user.location,
      locationLat:  user.locationLat,
      locationLon:  user.locationLon,
      fcmToken:     user.fcmToken,
      ...(user.lastChatPushTitle !== undefined && { lastChatPushTitle: user.lastChatPushTitle }),
      preferences:  user.preferences,
      createdAt:    user.createdAt,
      updatedAt:    user.updatedAt,
      // Omitir deletedAt cuando es undefined para evitar que el driver almacene null
      ...(user.deletedAt !== undefined && { deletedAt: user.deletedAt }),
      ...(user.bannedUntil !== undefined && { bannedUntil: user.bannedUntil }),
    };
  }
}
