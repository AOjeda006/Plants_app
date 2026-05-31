/**
 * @file HashService.ts
 * @description Servicio de hashing de contraseñas usando bcryptjs.
 * Centraliza el hashing para que los use cases no dependan directamente de bcryptjs.
 * @module Auth
 * @layer Presentation
 *
 * @injectable
 */

import { injectable } from 'inversify';
import bcrypt from 'bcryptjs';
import { authConfig } from '../../core/config/auth.config.js';

/**
 * Servicio de hashing de contraseñas con bcryptjs.
 *
 * @injectable
 */
@injectable()
export class HashService {
  /**
   * Genera el hash bcrypt de una contraseña en texto plano.
   *
   * @param password — Contraseña en texto plano.
   * @returns Hash bcrypt listo para almacenar en BD.
   */
  async hash(password: string): Promise<string> {
    return bcrypt.hash(password, authConfig.BCRYPT_SALT_ROUNDS);
  }

  /**
   * Compara una contraseña en texto plano con un hash almacenado.
   *
   * @param password — Contraseña en texto plano proporcionada por el usuario.
   * @param hash — Hash bcrypt almacenado en la base de datos.
   * @returns true si la contraseña coincide con el hash.
   */
  async compare(password: string, hash: string): Promise<boolean> {
    return bcrypt.compare(password, hash);
  }
}
