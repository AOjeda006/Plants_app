/**
 * @file JwtService.ts
 * @description Servicio de firma y verificación de tokens JWT.
 * Centraliza el uso de jsonwebtoken para que los use cases no dependan del paquete directamente.
 * @module Auth
 * @layer Presentation
 *
 * @injectable
 */

import { injectable } from 'inversify';
import jwt from 'jsonwebtoken';
import { authConfig } from '../../core/config/auth.config.js';
import { UnauthorizedException } from '../../core/exceptions/UnauthorizedException.js';

/**
 * Payload embebido en el token JWT.
 */
export interface UserPayload {
  /** Id del usuario (ObjectId serializado) */
  userId: string;
  /** Email del usuario */
  email: string;
  /** Rol del usuario. Opcional para compatibilidad con tokens legacy emitidos antes de la introducción del campo. */
  role?: 'user' | 'admin';
}

/**
 * Servicio de tokens JWT (firma y verificación).
 *
 * @injectable
 */
@injectable()
export class JwtService {
  /**
   * Genera un token JWT firmado con el payload indicado.
   *
   * @param payload — Datos a embeber en el token (userId, email).
   * @returns Token JWT como string.
   */
  sign(payload: UserPayload): string {
    return jwt.sign(payload, authConfig.JWT_SECRET, {
      expiresIn: authConfig.JWT_EXPIRATION as jwt.SignOptions['expiresIn'],
    });
  }

  /**
   * Verifica y decodifica un token JWT.
   *
   * @param token — Token JWT a verificar.
   * @returns Payload decodificado si el token es válido.
   * @throws {UnauthorizedException} Si el token es inválido o ha expirado.
   */
  verify(token: string): UserPayload {
    try {
      return jwt.verify(token, authConfig.JWT_SECRET) as UserPayload;
    } catch (err) {
      const isExpired = err instanceof jwt.TokenExpiredError;
      throw new UnauthorizedException(
        isExpired ? 'El token ha expirado' : 'Token inválido',
      );
    }
  }
}
