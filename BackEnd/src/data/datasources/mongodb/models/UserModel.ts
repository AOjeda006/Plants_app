/**
 * @file UserModel.ts
 * @description Define el nombre de la colección y el tipo de documento MongoDB para User.
 * SIN lógica de mapeo — la transformación entre documento y entidad es responsabilidad
 * exclusiva de los mappers (data/mappers/user_mapper.ts).
 * @module Auth
 * @layer Data
 */

import { ObjectId } from 'mongodb';

/** Nombre de la colección en MongoDB */
export const USER_COLLECTION = 'users';

/**
 * Tipo del documento MongoDB tal como se almacena en la base de datos.
 * Los campos usan ObjectId y Date nativos de MongoDB.
 * NO contiene métodos de negocio ni de mapeo.
 */
export interface UserDocument {
  _id: ObjectId;
  /** Rol del usuario. Opcional en BD para compatibilidad con documentos previos (default: 'user'). */
  role?: 'user' | 'admin';
  name: string;
  email: string;
  passwordHash: string;
  photo?: string;
  bannerPhoto?: string;
  bio?: string;
  location?: string;
  locationLat?: number;
  locationLon?: number;
  fcmToken?: string;
  /** Decisión #224: último título de push de chat enviado offline (dedup). */
  lastChatPushTitle?: string | null;
  preferences: {
    appearInChatSearch: boolean;
    considerWeatherByDefault: boolean;
    isPrivate?: boolean;
  };
  createdAt: Date;
  updatedAt: Date;
  deletedAt?: Date | null;
  bannedUntil?: Date | null;
}
