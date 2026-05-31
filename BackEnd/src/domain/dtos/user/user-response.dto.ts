/**
 * @file user-response.dto.ts
 * @description DTO de respuesta con datos públicos del usuario.
 * @module User
 * @layer Domain
 */

import { UserPreferences } from '../../entities/User.js';

/**
 * Datos del usuario seguros para exponer al cliente.
 * No incluye passwordHash ni fcmToken.
 */
export interface UserResponseDTO {
  id: string;
  name: string;
  email: string;
  /** Rol del usuario: 'user' o 'admin' */
  role: string;
  photo?: string;
  /** URL Cloudinary del banner/fondo de perfil */
  bannerPhoto?: string;
  bio?: string;
  location?: string;
  /** Latitud geográfica de la ubicación (capital de provincia España) */
  locationLat?: number;
  /** Longitud geográfica de la ubicación (capital de provincia España) */
  locationLon?: number;
  preferences: UserPreferences;
  createdAt: Date;
  /** Fecha hasta la que el usuario está suspendido (null si no está baneado) */
  bannedUntil?: Date;
}
