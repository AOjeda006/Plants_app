/**
 * @file auth.config.ts
 * @description Configuración de autenticación: JWT y hashing de contraseñas.
 * @module Auth
 * @layer Core
 */

import 'dotenv/config';

/**
 * Configuración de autenticación cargada desde variables de entorno.
 */
export const authConfig = {
  /** Clave secreta para firmar y verificar tokens JWT */
  JWT_SECRET: process.env.JWT_SECRET ?? (() => {
    throw new Error('JWT_SECRET no está definida en las variables de entorno');
  })(),

  /** Duración del access token. Default 30d (sesión persistente híbrida con
   *  auto-refresh silencioso). El valor se sobrescribe con JWT_EXPIRES_IN del .env. */
  JWT_EXPIRATION: process.env.JWT_EXPIRES_IN ?? '30d',

  /** Duración del refresh token */
  REFRESH_TOKEN_EXPIRATION: '30d',

  /** Número de rondas de salt para bcrypt */
  BCRYPT_SALT_ROUNDS: parseInt(process.env.BCRYPT_SALT_ROUNDS ?? '12', 10),
} as const;
