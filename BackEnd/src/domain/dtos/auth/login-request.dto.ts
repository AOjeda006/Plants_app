/**
 * @file login-request.dto.ts
 * @description DTO de solicitud de login de usuario.
 * @module Auth
 * @layer Domain
 */

import { IsEmail, IsString, MinLength } from 'class-validator';

/**
 * DTO de login. Validado en el controlador antes de llegar al use case.
 */
export class LoginRequestDTO {
  /** Email del usuario */
  @IsEmail()
  email!: string;

  /** Contraseña en texto plano */
  @IsString()
  @MinLength(1)
  password!: string;
}
